module Doozer
  class Middleware
    def initialize(app, args=nil)
      @app = app
      @args = args
    end
    def config
      @args[:config]
    end
    def logger
      @args[:config].logger
    end
    def route
      @args[:route]
    end
  end
  
  class MiddlewareBeforeDozerApp < Middleware
    def call(env)
      @app.call(env)
    end
  end
end