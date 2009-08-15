module Doozer
  module Exceptions
    
    # Runtime Error for handling Route intialization errors.
    class Route < RuntimeError
      def initialize(message)
        @message=message
      end
    end

  end
end