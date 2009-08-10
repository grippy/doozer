require 'rbconfig'
require 'logger'
require 'yaml'

module Doozer
  
  # This is the main Configs class which loads root/config/app.yml and root/config/database.yml
  #
  # It also provides a few helper methods like logger, env_path, base_url and app_name
  class Configs
   APP_PATH = Dir.pwd
   @@possible_orm = [:active_record, :data_mapper, :sequel]
   
   # Rack refers to production as deployment.
   def self.load(rack_env)
      p "APP_ROOT: #{APP_PATH}" 
      p "Loading configs for #{rack_env}"
      
      # TODO: remove this and replace with APP_PATH
      @@env_path = Dir.pwd 
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
        @@logger = Logger.new("#{APP_PATH}/log/#{rack_env}.log")
      end

      @@config[:rack_env] = rack_env
      # p ":rack_env set to #{@@config[:rack_env]}"

      begin
       @@config[:database] = Configs.symbolize_keys( YAML.load(File.read(File.join(APP_PATH,'config/database.yml'))) )
      rescue
       p "Failed to load config/database.yml"
      end

      begin
       @@config[:app] = Configs.symbolize_keys( YAML.load(File.read(File.join(APP_PATH,'config/app.yml'))) )
      rescue
       p "Failed to load config/app.yml"
      end
   end

   # We initialize the application logger in this Configs. This is then extended through to the ActiveRecord and is also available in ViewHelpers.
   def self.logger
     @@logger
   end
   
   # This is the file path the app was loaded under. Dir.pwd moves to root in daemon mode so we cache this.
   def self.env_path
     @@env_path
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
      
   # Return the app 404 url
   def self.page_not_found_url
     self.app[404] || nil
   end
   
   # Return the app 404 url
   def self.internal_server_error_url
     self.app[500] || nil
   end

  end
end