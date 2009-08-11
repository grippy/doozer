#= start/stop/restart webserver(s)
# This file is required in script/cluster. 
#
# Navigate to your app root and run it with the following commands.
#
# script/cluster
# -C command (start || stop || restart || test)
# -E environment (default: development || deployment)
# -D (daemonize) - This is automatically initialized in deployment mode. There should be no need to pass this unless you want to test it out in development mode.
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
@apps = []

for app in clusters[:apps]
  ip = app.split(':')[0]
  port = app.split(':')[1]
  @apps.push({:ip=>ip, :port=>port})
end

# Automatically starts a test instance of your appserver on http://localhost:5000. (No -E flag is required for this command).
def test
  cmd = "rackup #{@test_config}" 
  p "Command: #{cmd} -p 5000 -E test -o 127.0.0.1"
  system(cmd)
end

# <b>development</b>: Only starts the first configured (if more then one) address:port
#
# <b>deployment</b>: Automatically starts a new instance of your appserver for each defined cluster address:port
def start
  p "Starting clusters..."
  for app in @apps
    if @env == :deployment
      #need to check if application has a pid file so we don't start
      pid_file = "#{APP_PATH}/log/doozer.#{app[:port]}.pid"
      raise "pid file already exists for #{pid_file}" if File.exist?(pid_file)
      cmd = "rackup #{@config} -p #{app[:port]} -E #{@env.to_s} -s #{@server} -o #{app[:ip]} #{@daemonize} -P #{pid_file}" 
      p "Command: #{cmd}"
      system(cmd)
    else
      cmd = "rackup #{@config} -p #{app[:port]} -E #{@env.to_s} -s #{@server} -o #{app[:ip]}" 
      p "Command: #{cmd}"
      system(cmd)
      break
    end
  end
  p "Did they start?"
  system("ps -aux | grep rackup")
end

# Calls stop() and then start()
def restart
  stop
  start
end

# <b>development</b>: Only stops the first configured (if more then one) address:port
#
# <b>deployment</b>: Automatically stops all instances of your appserver for each defined cluster address:port
def stop
  system("ps -aux | grep rackup")
  p "Stoping clusters..."
  for app in @apps
    if @env == :deployment
      pid_file = "#{APP_PATH}/log/doozer.#{app[:port]}.pid"
      p "Reading pid from #{pid_file}" 
      if File.exist?(pid_file)
        File.open(pid_file, 'r'){ | f | 
          pid = f.gets.to_i
          p "Shutting down process #{pid}"
          system("kill -9 #{pid}")

        }
        File.delete(pid_file) 
      else
        p "pid file doesn't exist"
      end
    end
  end
  system("ps | grep rackup")
end

opts = OptionParser.new("", 24, '  ') { |opts|
  opts.banner = "Usage: script/clusters -C [command] -E [environment] -h"

  opts.separator ""
  opts.separator "Command options:"
  opts.on("-C", "--command COMMAND", "start, stop, restart, or test") { | c |
    @command = c.downcase.to_sym
  }
  
  opts.on("-E", "--env ENVIRONMENT", "default: development || deployment") { | e |
    @env = e.downcase.to_sym
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
    start()
  when :restart
    restart()
  when :stop
    stop()
  when :test
    test()
end



