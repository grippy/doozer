require 'active_record'
module Doozer
  module ORM
    def self.load
      db_config = Doozer::Configs.db()
      # ActiveRecord::Base.allow_concurrency = true
      ActiveRecord::Base.establish_connection(
        :adapter  => db_config["adapter"],
        :host     => db_config["host"],
        :username => db_config["username"],
        :password => db_config["password"],
        :database => db_config["database"]
      )
      printf "ORM: #{Doozer::Configs.orm()} initialized...\n"
      # printf "ORM: logging initialized"
      ActiveRecord::Base.logger = Doozer::Configs.logger 
    end
  end
end