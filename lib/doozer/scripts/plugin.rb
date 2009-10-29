#= Plugin

require 'optparse'
@gem = nil
@path = nil
@version = nil

opts = OptionParser.new("", 24, ' ') { |opts|
  opts.banner = "Usage: script/plugin -G gem_name -V version\n"
  opts.separator ""
  opts.separator "Command options:"
  
  opts.on("-G", "--gem NAME", "name of the gem to make") { | g |
    @game = g
  }

  opts.on("-P", "--path PATH", "Turn the path into a plugin") { | p |
    @path = p
  }
  opts.on("-V", "--version VERSION", "version of the gem/path to make") { | v |
    @version = v
  }
  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.parse! ARGV
}

def git(path, version)
  name = path.split('/').last.replace('.git')
  
  plugin_dir = "#{APP_PATH}/gems/plugins"
  printf  "Checking out #{path} to #{plugin_dir}\n"
  system("git clone #{path} #{plugin_dir}")
  if version
    name_with_version = "#{name}-#{version}" if version
    system("mv #{plugin_dir}/#{name} #{plugin_dir}/#{name_with_version}")
    
  else
    
  end
end

if @gem
  
end

if @path
  git(@path, @version) if @path.index('.git')
end
