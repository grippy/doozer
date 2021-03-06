require 'dm-core'
module Doozer
  
  # See for more info => http://datamapper.org/doku.php?id=getting_started_with_datamapper
  module ORM
    def self.load
      db_config = Doozer::Configs.db()
      DataMapper.setup(:default, {
        :adapter  => db_config["adapter"],
        :database => db_config["database"],
        :username => db_config["username"],
        :password => db_config["password"],
        :host     => db_config["host"]
      })
      puts "=> #{Doozer::Configs.orm()} initialized"
      DataMapper::Logger.new(STDOUT, :debug)
    end
    
    def self.after_request; end
    
  end
end