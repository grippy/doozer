require 'sequel'
module Doozer
  module ORM
    
    # See for details => http://sequel.rubyforge.org/rdoc/index.html
    def self.load
      db_config = Doozer::Configs.db()
      Doozer::Configs.db_conn = Sequel.connect({
        :adapter  => db_config["adapter"],
        :database => db_config["database"],
        :username => db_config["username"],
        :password => db_config["password"],
        :host     => db_config["host"]
      }) 
      p "ORM: #{Doozer::Configs.orm} initialized..."
    end
  end
end