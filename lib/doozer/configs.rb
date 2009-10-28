require 'rbconfig'
require 'logger'
require 'yaml'

module Doozer
  
  # This is the main Configs class which loads root/config/app.yml and root/config/database.yml
  #
  # It also provides a few helper methods like logger, app_path, base_url and app_name
  class Configs
   @@possible_orm = [:active_record, :data_mapper, :sequel]
   @@app_path = nil
   @@static_file = {}
   @@orm_loaded = false
   
   # Load all the config files for the application. Also instantiates a default application Logger.
   def self.load(rack_env)
      printf "Application path: #{app_path}\n" 
      printf "Loading configs for #{rack_env}\n"
      
      @@config = Config::CONFIG
      rack_env = (rack_env.kind_of? String) ? rack_env.to_sym : rack_env
      case rack_env
      when :development
      when :deployment
      when :test, :none
        rack_env = :test
      else
        raise ":development, :deployment, or :test are only environments allowed"
      end

      # set logging for environment
      if [:development, :test].include?(rack_env)
        @@logger = Logger.new(STDOUT)
      else
        @@logger = Logger.new("#{app_path}/log/#{rack_env}.log")
      end

      @@config[:rack_env] = rack_env
      # p ":rack_env set to #{@@config[:rack_env]}"

      begin
       @@config[:database] = Configs.symbolize_keys( YAML.load(File.read(File.join(app_path,'config/database.yml'))) )
      rescue
       printf "--Failed to load config/database.yml \n"
      end

      begin
       @@config[:app] = Configs.symbolize_keys( YAML.load(File.read(File.join(app_path,'config/app.yml'))) )
      rescue
       printf "--Failed to load config/app.yml\n"
      end

   end

   # We initialize the application logger in this Configs. This is then extended through to the ActiveRecord and is also available in ViewHelpers.
   def self.logger
     @@logger
   end
   
   # Hook for setting the application path.
   #
   # This allows the an application to be initialized from a different location then the project directory.
   def self.set_app_path(path=nil)
     @@app_path = path || Dir.pwd
   end

   # This is the file path the app was loaded under. Dir.pwd moves to root in daemon mode so we cache this.
   def self.app_path
     set_app_path if @@app_path.nil?
     return @@app_path
   end
   
   # Take a hash and turn all the keys into symbols
   def self.symbolize_keys(hash=nil)
     out = {}; hash.each { | k, val | out[k.to_sym] = val}
     return out
   end
   
   # Return the rack environment this application was loaded with.
   def self.rack_env
    return @@config[:rack_env] if not @@config[:rack_env].nil?
   end

   # Input a symbol and return the config for this sym
   def self.get(sym=nil)
     @@config[sym]
   end

   # Return the orm mapping gem name to load
   def self.orm
     begin 
       return @@config[:database][:orm] 
     rescue 
     end
     return nil
   end

   # Return the database configuration setting for the loaded environment
   def self.db
     return @@config[:database][@@config[:rack_env]] if not @@config[:database].nil?
   end

   def self.orm_loaded
     @@orm_loaded
   end
   
   def self.orm_loaded=(t)
     @@orm_loaded = t
   end
   
   # Only used for Sequel ORM for getting the db connection after connecting
   def self.db_conn
      @@db_conn
   end   

   # Only used for Sequel ORM to set the db connection
   def self.db_conn=(conn)
      @@db_conn = conn
   end   
     
   # Return the app configuration setting for the loaded environment
   def self.app
     return @@config[:app][@@config[:rack_env]]
   end
   
   # Return the app base url
   def self.base_url
     self.app["base_url"] || ""
   end
      
   # Return the app name
   def self.app_name
     self.app["name"] || ""
   end
   
   # Return the static root
   def self.static_root
     self.app["static_root"] || ""
   end

   # Return the app 404 url
   def self.page_not_found_url
     self.app[404] || nil
   end
   
   # Return the app 404 url
   def self.internal_server_error_url
     self.app[500] || nil
   end

    def self.static_url(path)
      return path if path.index('http://') or path.index('https://')
      key = "#{@@app_path}/#{static_root}#{path}"
      if not @@static_file[key].nil?
        return "#{path}?#{@@static_file[key]}"
      else
        begin
          time = File.stat(key).mtime
          hash = Digest::SHA1.hexdigest(time.to_s)[0...5]
          @@static_file[key] = hash
          return "#{path}?#{hash}"
        rescue => e
          logger.error(e.to_s)
        end
      end
      return path
    end
    
    def self.clear_static_files
      @@static_file = {}
    end

  end
end