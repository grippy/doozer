
module Doozer
  class Task
    def initialize(args=nil)
      @args = args
    end
    def help; end
    def run; end
  end
end