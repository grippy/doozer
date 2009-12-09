#= Tasks
# This file is required in script/task.
# Add files to /tasks where the specified task_name contains a class with TaskName and a 'run' class method.
# Running a task automatically loads Doozer::Config and the specified ORM. 
# Navigate to your app root and run it with the following commands.
#
# script/clusters 
# -T task_name
# -E environment (default: development || deployment)
# -A args
# -h Hellllpppp!!!
#
#== Example
# Suppose you have this file tasks/who_rocks.rb
#
# class WhoRocks
#   def description
#   """ description """
#   end
#   def help
#   """ help me! """
#   end
#   def run
#    p "You Do!"
#   end
# end
#
# run: script/task -T who_rocks
require 'optparse'
@env = :development
@task = nil
@args = nil
@help = false
@daemonize = false

opts = OptionParser.new("", 24, ' ') { |opts|
  opts.banner = "Usage: script/task -T task_name -E (default: development || deployment || test)"
  opts.separator ""
  opts.separator "Command options:"
  
  opts.on("-E", "--env ENVIRONMENT", "use ENVIRONMENT for defaults (default: development || deployment || test)") { |e|
    @env = e.to_sym
  }
  
  opts.on("-T", "--task TASK", "run task_name") { | t |
    @task = t
  }
  
  opts.on("-A", "--args ARGS", "args") { |a|
    @args = eval(a) if a and a.length
  }
  
  opts.on("-D", "--daemonize") {
    @daemonize = true
  }
  
  opts.on("-h", "--help", "Show this message") do
    @help = true
  end

  opts.parse! ARGV
}

def file_to_task(f, args=nil)
  require f
  file_name = f.split("/").last.gsub(/\.rb/,"")
  klass = Doozer::Lib.classify(file_name)
  return Object.const_get(klass).new(args), file_name
end

if @task
  file = File.join(APP_PATH, "tasks/#{@task}.rb")
  raise "Can't find this task file #{@task}" if file.nil?
  task, file_name = file_to_task(file, @args)
  if not @help
    puts "=> Running #{@task}"
    Doozer::Initializer.boot(@env)
    if @daemonize
      puts "=> Daemonize"
      log_file = "#{APP_PATH}/log/task/#{@task}.log"
      error_file = "#{APP_PATH}/log/task/#{@task}_errors.log"
      puts "=> Writing to log: #{log_file}"
      exit if fork
      Process.setsid
      exit if fork
      # Dir.chdir "/"
      File.umask 0000
      file = File.open(log_file, File::RDWR|File::APPEND|File::CREAT, 0600)
      STDIN.reopen(file)
      STDOUT.reopen(file)
      file = File.open(error_file, File::RDWR|File::APPEND|File::CREAT, 0600)
      STDERR.reopen(file)
      # STDIN.reopen "/dev/null" 
      # STDOUT.reopen "/dev/null", "a"
      # STDERR.reopen "/dev/null", "a"
    end
    task.run
  else
    puts ""
    puts "Task\n  #{@task}\n"
    puts "Description\n #{task.description}\n"
    puts "Help\n  #{task.help}\n"
  end
elsif @help
  puts opts;
  puts "Loading all tasks.."
  puts "Task | Description"
  tasks = Dir.glob(File.join(APP_PATH,'tasks/*.rb'))
  tasks.each { | f |
    task, file_name = file_to_task(f, nil)
    puts "=> #{file_name}: #{task.description}"
  }
end