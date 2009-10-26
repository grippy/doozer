#= Migrations
# This file is required in script/migrate. It loads the specified migration from the project/db directory and runs the migration with the specified direction. 
# Navigate to your project root and run it with the following commands.
#
# script/migrate 
# -V version:direction  (example: 1:up || 1:down)
# -E environment (default: development || deployment)
# -h Hellllpppp!!!
#
#== Examples
#
# Suppose you have this file db/001_initial_schema.rb
#
#== Example for ActiveRecord
#
# class InitialSchema < ActiveRecord::Migration
#   def self.up
#   end
#   def self.down
#   end
# end
#
#
#== Example for DataMapper
#
# require 'dm-more'
# class CreateUser
#   def self.up
#   end
#   def self.down
#   end
# end
#
#== Example for Sequel
#
# class InitialSchema
#   def self.db
#     Doozer::Configs.db
#   end
#   def self.up
#     db.create_table :examples do
#     end
#   end
#   def self.down
#     db.drop_table :examples
#   end
# end

require 'optparse'
@env = :development
@version = nil
@direction = nil

opts = OptionParser.new("", 24, ' ') { |opts|
  opts.banner = "Usage: script/migrate -V number:direction -E (default: development || deployment)"
  opts.separator ""
  opts.separator "Command options:"

  opts.on("-E", "--env ENVIRONMENT", "use ENVIRONMENT for defaults (default: development || deployment)") { |e|
    @env = e.to_sym
  }

  opts.on("-V", "--version VERSION", "use VERSION to upgrade or downgrade to the correct version number") { | v |
    if v.index(":up")
      @direction = :up
    elsif v.index(":down")
      @direction = :down
    else
      raise "Missing direction. Must be -V (num:up || num:down)"
    end
    @version = v.split(":")[0].to_i
  }
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  
  opts.parse! ARGV
}

raise "Missing Version and Direction in form of version:direction" if @version.nil? or @direction.nil?

#--boot it up
Doozer::Initializer.boot(@env)

# need to grab all the current migrations. assumes there isn't a migration with 000_*_.rb
migrations = [nil].concat( Dir.glob(File.join(APP_PATH,'db/*_*.rb')) )

printf "Loading migration files\n"
printf "Version: #{@version}\n"
printf "Direction: #{@direction}\n"

if @version > 0
  file = migrations[@version]
  raise "Can't find file for this migration" if file.nil?
  require file
  p "Migrating #{file}"
  klass = file.split("/").last.gsub(/\.rb/,"").split('_')
  klass = Doozer::Lib.classify(klass.slice(1, klass.length).join('_'))
  obj = Object.const_get(klass)
  
  case @direction
  when :up
    obj.up
  when :down
    obj.down
  end
end