require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'doozer'

class RoutingHelper < Test::Unit::TestCase
  
  def setup
    puts "=> Routing helper setup"
    @app_path = File.join(File.dirname(__FILE__), 'project')
    
    #--boot
    Doozer::Initializer.boot(:test, app_path=@app_path)
    
    #--instantiate Doozer::App
    @app = Doozer::App.new(args={})
    
  end
  
  def default_test
    
  end
end