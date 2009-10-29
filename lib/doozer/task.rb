
module Doozer
  class Task
    def initialize(args=nil)
      @args = args
    end
    def name; return self.class.to_s end
    def help; end
    def run; end
  end
end