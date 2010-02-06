
module Doozer
  class Task
    def initialize(args=nil)
      @args = args
    end
    def models(list=[])
      for m in list
        require "app/models/#{m.to_s}"
      end
    end
    def name; return self.class.to_s end
    def help; end
    def run; end
  end
end