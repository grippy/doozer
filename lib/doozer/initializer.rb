module Doozer
  
  # This is the main class which facilitates booting Doozer components and hooks.
  # 
  # Calling boot initializes Doozer in the following order:
  # 1. Doozer::Configs
  # 2. require ORM
  # 3. require root/config/environment.rb
  # 4. call after_orm_init
  # 5. require Doozer::App
  # 6. call before_rackup_init
  class Initializer
    @@after_orm = []
    @@before_rackup = []

    # env - :development, :deployment, or :test
    # app_path - optional path which overrides where the application is loaded from. Defaults to the Dir.pwd of script loading this file
    def self.boot(env, app_path=nil)
      #--load configs
      require 'doozer/configs'
      Doozer::Configs.set_app_path(app_path)
      Doozer::Configs.load(env)
      
      #--load orm
      Doozer::Initializer.orm

      #--load environment hooks
      Doozer::Initializer.environment

      #--call the after_orm_init features
      Doozer::Initializer.after_orm_init

      #--load app
      require 'doozer/app'

      #--call the before_rackup_init features
      Doozer::Initializer.before_rackup_init
    end
        
    # Checks to see if an ORM gem (active_record, data_mapper, or sequel) is specified in database.yml and loads it.
    def self.orm
      begin
      # load orm layer (if required)
        if not Doozer::Configs.orm.nil? and not Doozer::Configs.db.nil?
          require "doozer/orm/#{Doozer::Configs.orm}"
          Doozer::ORM.load
          Doozer::Configs.orm_loaded = true
        end
      rescue => e
        Doozer::Configs.logger.error(e)
      end
    end

    # Requires the root/config/environment.rb hooks. 
    #
    # This is where you can place your code to initialize additional plugins for models, extend ruby, or whatever else yor app requires.
    # 
    #=== Example environment.rb
    # Time::DATE_FORMATS[:month_and_year] = "%B %Y"
    # 
    # Doozer::Initializer.after_orm do | config |
    #   p "Extending some ORM, yo!"
    # end
    #
    # Doozer::Initializer.before_rackup do | config |
    #   p "Before rackup, horray for rackup!"
    # end
    def self.environment
      begin
        require "#{Doozer::Configs.app_path}/config/environment"
      rescue => e
        Doozer::Configs.logger.error(e)
      end
    end

    # TODO: test this again
    def self.console(env, app_path=nil)
      self.boot(env, app_path=app_path)
      app = Doozer::App.new(args={})
    end
    
    # Primary hook for extending/overriding ORM. Code block is pushed onto an array which allows for multiple hooks throughtout different files.
    # 
    # &block - code to execute after ORM is intialized
    def self.after_orm(&block)
      @@after_orm.push(block) if block_given?
    end
    
    # Primary hook for adding/overriding Doozer::ViewHelpers methods. Code block is pushed onto an array which allows for multiple hooks throughtout different files.
    #
    # &block - code to execute after prior to Doozer.App.new being intialized. 
    def self.before_rackup(&block)
      @@before_rackup.push(block) if block_given?
    end

    private
    def self.after_orm_init
        @@after_orm.each{ | block | instance_eval(&block)}
    end
    def self.before_rackup_init
        @@before_rackup.each{ | block | instance_eval(&block)}
    end
  end
end