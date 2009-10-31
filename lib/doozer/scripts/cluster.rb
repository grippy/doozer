#= start/stop/restart webserver(s)
# This file is required in script/cluster. 
#
# Navigate to your app root and run it with the following commands.
#
# script/cluster
# -C command (start || stop || restart || test)
# -E environment (default: development || deployment)
# -D (daemonize) - This is automatically initialized in deployment mode.
# -c config file - This is used to pass a config file for starting up unicorn
# -h Hellllpppp!!!
require 'optparse'

APP_PATH = Dir.pwd if APP_PATH.nil?
config =  Doozer::Configs.symbolize_keys( YAML.load(File.read(File.join(APP_PATH,'config/app.yml'))) )
clusters = Doozer::Configs.symbolize_keys(config[:clusters])

@command = nil
@env = :development
@daemonize = ''
@server = clusters[:server]
@config = DOOZER_PATH + '/doozer/rackup/server.ru'
@test_config = DOOZER_PATH + '/doozer/rackup/test.rb'
@config_file = '' # optional config file to use instead of the default unicorn config
@apps = []

for app in clusters[:apps]
  ip = app.split(':')[0]
  port = app.split(':')[1]
  @apps.push({:ip=>ip, :port=>port})
end

# Automatically starts a test instance of your appserver on http://localhost:5000. (No -E flag is required for this command).
def test
  cmd = "rackup #{@test_config}" 
  puts "=> #{cmd} -p 5000 -E test -o 127.0.0.1"
  system(cmd)
end

# <b>development</b>: Only starts the first configured (if more then one) address:port
#
# <b>deployment</b>: Automatically starts a new instance of your appserver for each defined cluster address:port
def start
  puts "Starting clusters..."
  for app in @apps
    if @env == :deployment
      #need to check if application has a pid file so we don't start
      pid_file = "#{APP_PATH}/log/doozer.#{app[:port]}.pid"
      raise "pid file already exists for #{pid_file}" if File.exist?(pid_file)
      cmd = "rackup #{@config} -p #{app[:port]} -E #{@env.to_s} -s #{@server} -o #{app[:ip]} #{@daemonize} -P #{pid_file}" 
      puts "=> #{cmd}"
      system(cmd)
    else
      cmd = "rackup #{@config} -p #{app[:port]} -E #{@env.to_s} -s #{@server} -o #{app[:ip]}" 
      puts "=> #{cmd}"
      system(cmd)
      break
    end
  end
  puts "Did they start?"
  system("ps -aux | grep rackup")
end

# Call to start unicorn server
#
# Set the app.yml clusters server to unicorn complete with one ip:port value.
#
# You can also pass an optional value -c FILE to override the default unicorn conf.
#
# See Unicorn::Configurator for more details => http://unicorn.bogomips.org/Unicorn/Configurator.html 
#
# See this page for supported signals => http://unicorn.bogomips.org/SIGNALS.html
def start_unicorn
  puts "Starting unicorn..."
  for app in @apps
    # unicorn
    @config_file = "-c #{@config_file}" if @config_file != ''
    cmd = "unicorn  -p #{app[:port]} -E #{@env.to_s} -o #{app[:ip]} #{@daemonize} #{@config_file} #{@config}"
    puts "=> #{cmd}"
    system(cmd)
    break
  end
  puts "Did they start?"
  system("ps -aux | grep unicorn")
end

# Calls stop() and then start()
def restart
  stop
  start
end

# Calls stop_unicorn() and then start_unicorn()
def restart_unicorn
  stop_unicorn
  start_unicorn
end

# <b>development</b>: Only stops the first configured (if more then one) address:port
#
# <b>deployment</b>: Automatically stops all instances of your appserver for each defined cluster address:port
def stop
  system("ps -aux | grep rackup")
  puts "Stoping clusters..."
  for app in @apps
    if @env == :deployment
      pid_file = "#{APP_PATH}/log/doozer.#{app[:port]}.pid"
      puts "=> Reading pid from #{pid_file}" 
      if File.exist?(pid_file)
        File.open(pid_file, 'r'){ | f | 
          pid = f.gets.to_i
          puts "=> Shutting down process #{pid}"
          system("kill -9 #{pid}")

        }
        File.delete(pid_file) 
      else
        puts "ERROR => pid file doesn't exist"
      end
    end
  end
  sleep(1)
  system("ps -aux | grep rackup")
end

# <b>development</b>: Only stops the first configured (if more then one) address:port
#
# <b>deployment</b>: Automatically stops the first master process/cluster defined for address:port
def stop_unicorn
  system("ps -aux | grep unicorn")
  puts "Stoping unicorn..."
  for app in @apps
    if @env == :deployment
      pid_file = "#{APP_PATH}/log/unicorn.pid"
      puts "=> Reading pid from #{pid_file}" 
      if File.exist?(pid_file)
        system("kill -QUIT `cat #{pid_file}`")
      else
        puts "ERROR => pid file doesn't exist"
      end
    end
    break
  end
  sleep(1)
  system("ps -aux | grep unicorn")
end

opts = OptionParser.new("", 24, '  ') { |opts|
  opts.banner = "Usage: script/cluster -C [command] -E [environment] -h"
  opts.separator ""
  opts.separator "Command options:"
  opts.on("-C", "--command COMMAND", "start, stop, restart, or test") { | c |
    @command = c.downcase.to_sym
  }
  opts.on("-E", "--env ENVIRONMENT", "default: development || deployment") { | e |
    @env = e.downcase.to_sym
  }
  opts.on("-c", "--config-file FILE", "optional config file to use for server (supported by unicorn, etc.)") { | cf |
    @config_file = cf || ''
  }
  
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
    
  opts.parse! ARGV
}

@daemonize = '-D' if @env == :deployment

case @command
  when :start
    @server != 'unicorn' ? start() : start_unicorn()
  when :restart
    @server != 'unicorn' ? restart() : restart_unicorn()
  when :stop
    @server != 'unicorn' ? stop() : stop_unicorn()
  when :test
    test()
end



