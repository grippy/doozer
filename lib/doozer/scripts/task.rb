#= Tasks
# This file is required in script/task.
# Add files to /tasks where the specified task_name contains a class with TaskName and a 'run' class method.
# Running a task automatically loads Doozer::Config and the specified ORM. You must require all other files your tasks require beyond these.
# Navigate to your app root and run it with the following commands.
#
# script/clusters 
# -T task_name
# -E environment (default: development || deployment)
# -h Hellllpppp!!!
#
#== Example
# Suppose you have this file tasks/who_rocks.rb
#
# class WhoRocks
#   def self.run
#    p "You Do!"
#   end
# end
#
# run: script/task -T who_rocks
require 'optparse'
@env = :development
@task = nil

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

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.parse! ARGV
}

raise "Missing task_name" if @task.nil?

#--boot it up
Doozer::Initializer.boot(@env)

if @task
  file = File.join(APP_PATH, "tasks/#{@task}.rb")
  raise "Can't find this task file #{@task}" if file.nil?
  p "Running #{@task}"
  klass = file.split("/").last
  require file
  klass = Doozer::Lib.classify(klass.gsub(/\.rb/,""))
  Object.const_get(klass).run
end