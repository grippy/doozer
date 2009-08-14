module Doozer
  module Exceptions
    
    class Route < RuntimeError
      def initialize(message)
        @message=message
      end
    end

  end
end