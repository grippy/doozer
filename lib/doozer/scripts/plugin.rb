#= Plugin

require 'optparse'
@freeze = nil
@path = nil
@version = nil
@force = false


opts = OptionParser.new("", 24, ' ') { |opts|
  opts.banner = "Usage:\n script/plugin -F gem -V version -f\n script/plugin -P path -V version -f"
  opts.separator ""
  opts.separator "Command options:"
  
  opts.on("-P", "--path PATH", "Turn the path into a plugin.\n\n Possible options:\n 1. git repos\n2. Local path") { | p |
    @path = p
  }

  opts.on("-F", "--freeze gem", "Freeze gem to gems/doozer or gems/plugin directory if match is found. Use -V or --version to locate exact version") { | name |
    @freeze = name
  }

  opts.on("-V", "--version VERSION", "version of the gem/path to freeze") { | v |
    @version = v
  }

  opts.on("-f", "--force", "Remove current plugin before installing") {
    @force = true
  }

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit
  end

  opts.parse! ARGV
}

def git(path, version, force)
  puts "Checking out remote git repo..."  
  name = path.split('/').last.gsub(/\.git/,'')
  name  += "-#{version}" if version
  plugin_dir = "#{APP_PATH}/gems/plugins"
  plugin = "#{plugin_dir}/#{name}"
  puts "=> #{path} to #{plugin}"
  system("rm -rf #{plugin}") if force
  system("git clone #{path} #{plugin}")
  if version
    system("cd #{plugin}; git checkout #{version}")
  end
end

def freeze(gem_name, version, force)
  # locate the gem to freeze
  puts "Freezing gem..."
  path = `gem which #{gem_name} -a`
  source = gem_name
  if path.downcase.index('can\'t find')
    puts path
    exit
  end
  path.gsub!(/\n/, '')
  gem_path = nil
  if version
    name = "#{gem_name}-#{version}"
    # check if the return from the which statement is actually the correct gem
    if path.index(name)
      gem_path=path.split(name)[0]
    else
      # attempt to locate the gem+version specified
      gem_path = path.split(gem_name)[0]
      if not File.directory?("#{gem_path}#{name}")
        puts "=> Can't find #{gem_path}#{name}"
        system("gem list #{gem_name}")
        exit
      end
    end
    gem_name = name
  end
  if gem_path.nil?
    parts = path.split(gem_name)
    gem_path = parts[0]
    gem_name += parts[1].split('/')[0]    
  end
  gem_path += gem_name
  copy(gem_path, force)
end

def copy(path, force)
  if File.directory?("#{path}")
    cp_to_path = "#{APP_PATH}/gems/"
    if path.index('doozer')
      cp_to_path += 'doozer'
    else
      cp_to_path += 'plugins'
    end
    puts "=> Copying: #{path}..."
    puts "=>  To: #{cp_to_path}"
    system("cp -R #{'-f' if force} #{path} #{cp_to_path}")
    puts "=> Completed!"
    puts "=> Don't forget to initialize your plugin in gems/plugins/init.rb"
  else
    puts "ERROR => #{path} doesn't appear to be a valid path"
  end
end

if @freeze
  freeze(@freeze, @version, @force)
elsif @path
  if @path.index('.git')
    git(@path, @version, @force)
  else
    copy(@path, @force)
  end
end
