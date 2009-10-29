require 'erb'

module Doozer
  
  #= Generate Project Skeletons and Files
  class Generator
    APP_PATH = Dir.pwd
    PATH = File.expand_path( File.join(File.dirname(__FILE__), '..', '..', 'templates') )
    
    def self.run(*args)
      return help_all if args.empty?
      
      action = args[0].downcase
      if not ['generate', '-h', '--help', '-v', '--version'].include?(action)
        skeleton(action)
      else
        if action == 'generate'
          
          action = args[1]
          case action.to_sym
            when :model, :"-M"
              if args.length == 3
                name = args[2]
                Doozer::Configs.load(:development)
                model(Doozer::Configs.orm, name.downcase)
              else
                help?(:help, :model)
              end
            when :view, :"-V"
              args.push('html') if args.length == 3
              if args.length == 4
                name = args[2]
                formats = args[3].split(',')
                view(name.downcase, formats)
              else
                help?(:help, :view)
              end
            when :controller, :"-C"
              if args.length == 3
                name = args[2]
                controller(name.downcase)
              else
                help?(:help, :controller)
              end
            when :helper, :"-H"
              if args.length == 3
                name = args[2]
                helper(name.downcase)
              else
                help?(:help, :helper)
              end            
            when :db, :migrate, :migration, :"-D"
              if args.length == 3
                name = args[2]
                Doozer::Configs.load(:development)
                migrate(Doozer::Configs.orm, name.downcase)
              else
                help?(:help, :migrate)
              end
            when :task, :"-T"
              if args.length == 3
                name = args[2]
                task(name.downcase)
              else
                help?(:help, :task)
              end            
            else
            help_all
          end
        elsif ['-v', '--version'].include?(action)
          puts "Doozer #{Doozer::Version::STRING}"
        else
          help_all
        end
      end
    end
    
    def self.help_all
      puts "Doozer Version: #{Doozer::Version::STRING}"
      puts "Commands"
      help(:project)
      help(:model)
      help(:view)
      help(:controller)
      help(:helper)
      help(:migrate)
      help(:task)
    end
    
    def self.controller(name)
      return if help?(name, :controller) 
      puts "Generating File(s)..."
      path = "#{APP_PATH}/app/controllers/#{name.downcase}_controller.rb"
      if not File.exist?(path)
        puts "=> Generating controller: #{path}"
        file = File.new(path, "w+")
        if file
            template = "class #{Doozer::Lib.classify(name)}Controller < ApplicationController\nend"
            file.syswrite(template)
            #make the view directory for this controller
            path = "#{APP_PATH}/app/views/#{name.downcase}"
            if not File.exist?(path)
                puts "=> Generating view folder: #{path}"
                FileUtils.mkdir path
            end
        else
           puts "ERROR => Unable to open file!"
        end
      else
        puts "Skipping: #{path} (already exists)"
      end      
    end

    def self.model(orm, name)
      return if help?(name, :model)       
      raise "No ORM is defined. Please set this in database.yml" if orm.nil?
      puts "Loaded ORM: #{orm}"        
      path = "#{APP_PATH}/app/models/#{name}.rb"
      if not File.exist?(path)
        puts "=> Generating model: #{path}"
        file = File.new(path, "w+")
        if file
           template = eval("model_#{orm}('#{name}')")
           file.syswrite(template)
        else
           puts "ERROR => Unable to open file!"
        end
      else
        puts "Skipping: #{path} (already exists)"
      end
    end
    def self.model_active_record(name)
      klass=Doozer::Lib.classify(name)
      return """#= #{klass}
class #{klass} < ActiveRecord::Base
end 
"""
    end      
    def self.model_data_mapper(name)
      klass = Doozer::Lib.classify(name)
      return """#= #{klass}
class #{klass}
  include DataMapper::Resource
  property :id,         Serial
end
            """
    end
    def self.model_sequel(name)
      klass = Doozer::Lib.classify(name)
      return """ #see http://sequel.rubyforge.org/rdoc/index.html
#= #{klass}
class #{klass} < Sequel::Model
end 
"""
    end

    def self.view(view, formats)
      return if help?(view, :view) 
      puts "Generating View File(s)..."
      raise "Not sure which controller to associate this view with. Needs to be controller_name/action_name. Example: index/login" if not view.index('/')
      formats.each{|f|
        file="#{APP_PATH}/app/views/#{view}.#{f.strip}.erb"
        if not File.exist?(file)
          puts "=> Generating view: #{file}"
          FileUtils.touch file
        else
          puts "Skipping: #{file} (already exists)"
        end
      }
    end
    
    def self.migrate(orm, name)
      return if help?(name, :migrate)
    
      raise "No ORM is defined. Please set this in database.yml" if orm.nil?      
      version = migrate_next
      puts "Loaded ORM: #{orm}"
      path = "#{APP_PATH}/db/#{version}_#{name.downcase}.rb"
      if not File.exist?(path)
        puts "=> Generating migration: #{path}"
        file = File.new(path, "w+")
        if file
           template = eval("migrate_#{orm}('#{name}')")
           file.syswrite(template)
        else
           puts "ERROR => Unable to open file!"
        end
      else
        puts "Skipping: #{path} (already exists)"
      end
    end
    def self.migrate_next
      migrations = Dir.glob(File.join(APP_PATH,'db/*_*.rb')).reverse
      for m in migrations
        file = m.split('/').last
        if file.index('_')
          num = file.split('_').first
          return "%03d" % (num.to_i + 1) if num.index('0')
        end
      end
      return "%03d" % 1
    end
    def self.migrate_active_record(name)
      klass = Doozer::Lib.classify(name)
      return """
class #{klass} < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
    end
  end
  def self.down
    ActiveRecord::Base.transaction do
    end
  end
end
"""
    end
    def self.migrate_data_mapper(name)
      klass = Doozer::Lib.classify(name)
      return """
# See for more details
# http://datamapper.rubyforge.org/dm-core/
# http://datamapper.rubyforge.org/dm-more/
# http://github.com/datamapper/dm-more/tree/master/dm-migrations
require 'dm-more'
class #{klass}
  def self.up
  end
  def self.down
  end
end
"""
    end
    def self.migrate_sequel(name)
      klass = Doozer::Lib.classify(name)
      return """
class #{klass}
  def self.db
    Doozer::Configs.db
  end
  def self.up
    # db.create_table :name do
    # end
  end
  def self.down
    # db.drop_table :name
  end
end
"""
    end
    
    def self.task(name)
      return if help?(name, :task)
      puts "Generating file..."        
      path = "#{APP_PATH}/tasks/#{name}.rb"
      if not File.exist?(path)
        puts "=> Generating task: #{path}"
        file = File.new(path, "w+")
        if file
           klass = Doozer::Lib.classify(name)
           template = """
#= Task #{klass}
#
class #{klass} < Doozer::Task
  def description
    \"\"\"Place your task description here\"\"\"
  end

  def help
    \"\"\"Place your task help here\"\"\"
  end

  def run
    # Place your task here
    # @args holds evaluated args string
  end
end
"""
           file.syswrite(template)
        else
           puts "ERROR => Unable to open file!"
        end
      else
        puts "Skipping: #{path} (already exists)"
      end
    end

    def self.helper(name)
      return if help?(name, :helper)
      puts "Generating file..."
      path = "#{APP_PATH}/app/helpers/#{name}_helper.rb"
      if not File.exist?(path)
        puts "=> Generating helper: #{path}"
        file = File.new(path, "w+")
        if file
           klass = Doozer::Lib.classify(name)
           template = """
#= #{klass}Helper
module #{klass}Helper
end
"""
           file.syswrite(template)
        else
           puts "ERROR => Unable to open file!"
        end
      else
        puts "Skipping: #{path} (already exists)"
      end
    end
    
    def self.help?(name, action=nil)
      if name.to_sym == :"-h" or name == :help
        puts "Commands:"
        help(action)
        return true
      end
      return false
    end
    def self.help(action=nil)
      h = ""
      case action

        when :project
          h += """
Project - Create a new Doozer skeleton.
  Command: doozer project_name 
  Example: doozer hello_world\n"""
        when :model, :"-M"
          h += """
Model - Create a new model file in project/app/models with a class name of ModelName for the configured ORM.
  Command: doozer generate (model or -M) model_name
  Example: doozer generate model user\n"""
        when :view, :"-V"
          h += """
View - Create a view erb file in project/app/views for each of the provided formats. If format not specified an html format is automatically created.
  Command: doozer generate (view or -V) controller_name/action_name format_csv
  Example: doozer generate view admin/login html,xml,json,etc\n"""
        when :controller, :"-C"
          h += """
Controller - Create a controller file in project/app/controllers (and view folder) with a class name ControllerName.
    Command: doozer generate (controller or -C) controller_name 
    Example: doozer generate controller admin\n"""
        when :helper, :"-H"
          h += """
Helper - Create a helper file in project/app/helpers with the module name of HelperName. '_helper' is automatically appended to the helper_name.
    Command: doozer generate (helper or -H) helper_name 
    Example: doozer generate helper helper_name\n"""    
        when :db, :migrate, :migration, :"-D"
          h += """
Migration - Create a migration file in project/db with the next available version number and with a class name of MigrationName for the specified ORM.
    Command: doozer generate (db, migrate, migration or -D) migration_name 
    Example: doozer generate migrate create_user\n"""
        when :task, :"-T"
          h += """
Task - Create a task file in project/tasks with the class name of TaskName.
    Command: doozer generate (task or -T) task_name 
    Example: doozer generate task task_name\n"""
      end
      puts h
    end

    # TODO: Dry this up...
    def self.skeleton(name)
    
      # create application skeleton
      if not File.exist?(name)
        puts "Creating #{name}/"
        system("mkdir #{name}")
      else
        puts "Skipping application directory (already exists)"
      end

      #create app folder
      if not File.exist?("#{name}/app")
        puts "=> Creating app directory"
        system("mkdir #{name}/app")
      else
        puts "Skipping #{name}/app directory (already exists)"
      end
      
      #copy controllers
      if not File.exist?("#{name}/app/controllers")
        puts "=> Creating #{name}/app/controllers directory and files"
        system("mkdir #{name}/app/controllers")
        system("cp #{skeleton_path 'app/controllers/*.rb'} #{name}/app/controllers")
      else
        puts "Skipping #{name}/app/controllers directory (already exists)"
      end

      #copy models
      if not File.exist?("#{name}/app/models")
        puts "=> Creating #{name}/app/models directory and files"
        system("mkdir #{name}/app/models")
      else
        puts "Skipping #{name}/app/models directory (already exists)"
      end

      #copy views
      if not File.exist?("#{name}/app/views")
        puts "=> Creating #{name}/app/views directory and files"
        system("mkdir #{name}/app/views")
      else
        puts "Skipping #{name}/app/views directory (already exists)"
      end

      #copy views/layouts
      if not File.exist?("#{name}/app/views/layouts")
        puts "=> Creating #{name}/app/views/layouts directory and files"
        system("mkdir #{name}/app/views/layouts")
        system("cp #{skeleton_path 'app/views/layouts/*.erb'} #{name}/app/views/layouts")
      else
        puts "Skipping #{name}/app/views/layouts directory (already exists)"
      end

      #copy views/index
      if not File.exist?("#{name}/app/views/index")
        puts "=> Creating #{name}/app/views/index directory and files"
        system("mkdir #{name}/app/views/index")
        system("cp #{skeleton_path 'app/views/index/*.erb'} #{name}/app/views/index")
      else
        puts "Skipping #{name}/app/views/index directory (already exists)"
      end

      #copy views/global
      if not File.exist?("#{name}/app/views/global")
        puts "=> Creating #{name}/app/views/global directory and files"
        system("mkdir #{name}/app/views/global")
        system("cp #{skeleton_path 'app/views/global/*.erb'} #{name}/app/views/global")
      else
        puts "Skipping #{name}/app/views/global directory (already exists)"
      end

      #copy helpers
      if not File.exist?("#{name}/app/helpers")
        puts "=> Creating #{name}/app/helpers directory and files"
        system("mkdir #{name}/app/helpers")
        system("cp #{skeleton_path 'app/helpers/*.rb'} #{name}/app/helpers")  
      else
        puts "Skipping #{name}/app/helpers directory (already exists)"
      end

      #copy configs
      if not File.exist?("#{name}/config")
        puts "=> Creating #{name}/config directory and files"
        system("mkdir #{name}/config")
        system("cp #{skeleton_path 'config/*.yml'} #{name}/config")
        system("cp #{skeleton_path 'config/*.rb'} #{name}/config")
        
        ## load boot.erb replace version number and save as boot.rb
        boot_skel = skeleton_path 'config/boot.erb'
        results = []
        @version = Doozer::Version::STRING
        File.new(boot_skel, "r").each { |line| results << line }
        boot = ERB.new(results.join(""))
        File.open("#{name}/config/boot.rb", 'w') {|f| f.write(boot.result(binding)) }
      else
        puts "Skipping #{name}/config directory (already exists)"
      end

      # create gems folder
      if not File.exist?("#{name}/gems")
        puts "=> Creating #{name}/gems directory"
        system("cp -R #{skeleton_path 'gems'} #{name}")
        system("mkdir #{name}/gems/doozer")
      else
        puts "Skipping #{name}/gems directory (already exists)"
      end

      # create log folder
      if not File.exist?("#{name}/log")
        puts "=> Creating #{name}/log directory"
        system("mkdir #{name}/log")
      else
        puts "Skipping #{name}/log directory (already exists)"
      end

      #copy db
      if not File.exist?("#{name}/db")
        puts "=> Creating #{name}/db directory and files"
        system("mkdir #{name}/db")
      else
        puts "Skipping #{name}/db directory (already exists)"
      end

      #copy lib
      if not File.exist?("#{name}/lib")
        puts "=> Creating #{name}/lib directory and files"
        system("mkdir #{name}/lib")
      else
        puts "Skipping #{name}/lib directory (already exists)"
      end

      #copy script
      if not File.exist?("#{name}/script")
        puts "=> Creating #{name}/script directory and files"
        system("mkdir #{name}/script")
        system("cp #{skeleton_path 'script/*'} #{name}/script")
      else
        puts "Skipping #{name}/script directory (already exists)"
      end

      #copy static
      if not File.exist?("#{name}/static")
        puts "=> Creating #{name}/static directory and files"
        system("mkdir #{name}/static")
        system("cp #{skeleton_path 'static/*.*'} #{name}/static/")
      else
        puts "Skipping #{name}/static directory (already exists)"
      end

      #copy static/images
      if not File.exist?("#{name}/static/images")
        puts "=> Creating #{name}/script/images directory and files"
        system("mkdir #{name}/static/images")
      else
        puts "Skipping #{name}/static/images directory (already exists)"
      end

      #copy static/css
      if not File.exist?("#{name}/static/css")
        puts "=> Creating #{name}/script/css directory and files"
        system("mkdir #{name}/static/css")
        system("cp #{skeleton_path 'static/css/*.css'} #{name}/static/css")
      else
        puts "Skipping #{name}/static/css directory (already exists)"
      end

      #copy static/images
      if not File.exist?("#{name}/static/html")
        puts "=> Creating #{name}/script/html directory and files"
        system("mkdir #{name}/static/html")
      else
        puts "Skipping #{name}/static/html directory (already exists)"
      end

      #copy static/images
      if not File.exist?("#{name}/static/js")
        puts "=> Creating #{name}/script/js directory and files"
        system("mkdir #{name}/static/js")
        system("cp #{skeleton_path 'static/js/*.js'} #{name}/static/js")
      else
        puts "Skipping #{name}/static/js directory (already exists)"
      end

      #copy test
      if not File.exist?("#{name}/test")
        puts "=> Creating #{name}/test directory and files"
        system("mkdir #{name}/test")
        system("cp #{skeleton_path 'test/*.rb'} #{name}/test")
        system("mkdir #{name}/test/fixtures")
        system("cp #{skeleton_path 'test/fixtures/*.rb'} #{name}/test/fixtures")
      else
        puts "Skipping test directory (already exists)"
      end

      #copy test
      if not File.exist?("#{name}/tasks")
        puts "=> Creating #{name}/tasks directory and files"
        system("mkdir #{name}/tasks")
      else
        puts "Skipping #{name}/test directory (already exists)"
      end

      #copy rakefile
      system("cp #{skeleton_path 'Rakefile'} #{name}")

    end
    
    def self.skeleton_path(file)
      "#{PATH}/skeleton/#{file}"
    end
  
  end
end