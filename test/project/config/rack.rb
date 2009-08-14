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