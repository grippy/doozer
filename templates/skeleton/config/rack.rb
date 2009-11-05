# By default doozer maps everything against "/"
#
# This file is required inside the main doozer/rackup/server.ru config.
# Make sure everything inside the stack method conforms to the Rack::Builder spec.
#
# You can map urls to differnt rack applications by plugging them in here...
# Example on how to hook up another rack app to the stack
class HelloWorld
  def call(env)
    [200, {"Content-Type" => "text/html"}, "Hello World!!!\n"]
  end
end

# Here's an example of how to create an after doozer app middleware
# This class inherits Doozer::Middleware which has a few helper methods for passing Doozer::App calls on down the line
# You can define each route to call :middleware_after=>ClassName
# This example removes all tabs and carriage returns to slim the response
class AfterDoozer < Doozer::Middleware
  def call(env)
    status, header, response = @app
    # logger.info(self.class.to_s)
    if route and response.is_a?(Rack::Response)
      response.body.each{ | p | p.gsub!(/\t|^\n|^\n\n/, '') } if not [:json, :js].include?(route.format)
    end
    [status, header, response]
  end
end

# This module#class is hooked into the pipeline before Doozer::App is called.
# It inherits from Doozer::Middleware so it has access to #config but not #route
module Doozer
  class MiddlewareBeforeDozerApp < Doozer::Middleware
    def call(env)
      # puts "MiddlewareBeforeDozerApp2"
      # logger.info("here")
      status, header, response = @app.call(env)
      [status, header, response]
    end
  end
end
# map additional rack apps here..
def stack
  # map your apps here...
  map "/hello" do
    run HelloWorld.new
  end

  map "/lobster" do
    require 'rack/lobster'
    use Rack::ShowExceptions
    use Rack::Auth::Basic, "Lobster 2.0" do |username, password|
      'secret' == password
    end
      run Rack::Lobster.new  
  end

end