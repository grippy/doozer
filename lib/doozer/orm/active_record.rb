require 'active_record'
module Doozer
  module ORM
    def self.load
      db_config = Doozer::Configs.db()
      #ActiveRecord::Base.allow_concurrency = true
        config = {
          :adapter  => db_config["adapter"],
          :host     => db_config["host"],
          :username => db_config["username"],
          :password => db_config["password"],
          :database => db_config["database"]
        }
      config[:pool] = db_config["pool"] if db_config["pool"]
      config[:reconnect] = db_config["reconnect"] if db_config["reconnect"]
      
      ActiveRecord::Base.establish_connection(config)
      puts "=> #{Doozer::Configs.orm()} initialized"
      ActiveRecord::Base.logger = Doozer::Configs.logger
    end
    
    def self.after_request
      ActiveRecord::Base.clear_active_connections!
    end
    
  end
end