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
      config.logger
    end
    def route
      @args[:route]
    end

  end
end