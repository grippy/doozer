module Doozer
  module Exception
    
    class Route < RuntimeError
      def initialize(message)
        @message=message
      end
    end

  end
end