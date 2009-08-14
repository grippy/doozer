module Doozer
  class Redirect < RuntimeError
    attr_accessor :url
    attr_reader :status
    
    def initialize(url, opts={})
      super "redirect"
      @url=(url=="") ? "/" : url
      @status = (opts[:status]) ? opts[:status] : nil
    end
  end
end