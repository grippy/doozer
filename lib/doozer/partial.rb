require "erb"
require "doozer/lib"
require "doozer/view_helpers"

module Doozer
  
  # This class facilitates loading and rendering of partials.
  #
  # A partial is an ERB template which starts with an underscore. They behave the same as action view ERB template with the only difference of not having access to Controller instance variables.
  #
  # An example partial: app/views/controller_name/_partial.html.erb
  #
  # By default, the Doozer scaffold creates an app/views/global folder which can be used to place global partials like headers, footers, etc.
  #
  # Partials have access to Doozer::ViewHelpers.
  #
  # All view helpers in app/helpers are automatically included in the Partial class during app initialize.
  #
  # A partial can render another partial and so on and so on.
  class Partial
    attr_accessor :erb, :route
    
    include ERB::Util
    include Doozer::Util::Logger
    include Doozer::ViewHelpers
    
    # APP_PATH = Dir.pwd
    @@partials={}
    
    def initialize(erb, locals, route)
      @erb = erb
      @route = route
      if locals.kind_of? Hash
        locals.each_pair {|key, value| 
          #p "#{key}:#{value}"
          self.instance_variable_set("@#{key}".to_sym, value) # :@a, value
        }
      end
    end
    
    def bind
      @erb.result(binding)
    end

    # This class method lazily loads and caches the erb templates of the requested partials
    def self.partial(file=nil, locals={}, route=route)
      #p "Class method: Doozer::Partial#partial"
      if file.index("/").nil?
        name = "#{route.controller}/_#{file}" 
      else
        name = "#{file.gsub(/\//,'/_')}"
      end
      load_partial(name) if  @@partials[name].nil?
      erb = @@partials[name]
      if erb
          partial = Doozer::Partial.new(erb, locals, route)
          partial.bind()
      else
        printf "--no partial exists for #{file}\n"
      end
    end
    
    # Renders and returns a partial template with the given file_name and local variables.
    #
    # * file - expects a string. By default, if you don't pass a controller, it's assumed the lookup location is the current route.controller path in the views folder.
    #   You must omit the underscore when passing the file_name. 
    #   A partial is automatically assumed to be html format. It shouldn't matter if you display an html partial inside a view with a different format.
    #
    # * locals - All local key/values are instantiated as instance variables acessable from the partial template. The controller.request variable is appended to locals and is also accessable as an instance variable from the partial template.
    def partial(file=nil, locals={})
      locals[:request] = @request if not @request.nil?
      Doozer::Partial.partial(file, locals, route=@route)
    end

    # Load and cache partial ERB template with the given file_name.
    def self.load_partial(name)
      file = File.join(app_path,"app/views/#{name}.html.erb")
      results = []
      begin
        File.new(file, "r").each { |line| results << line }
        # TODO: throw error if doesn't exist
        @@partials[name] = ERB.new(results.join(""))
      rescue
        p "sorry couldn't load partial #{name} (#{file})"
      end
    end    
    
    # Class methods for clearing all cached partials. Mainly a dispatcher for the file watcher to pick up new changes without having to restart the appserver in development mode.
    def self.clear_loaded_partials
      @@partials = {}
    end
    
    # Class method for including a view helper.
    def self.include_view_helper(helper)
      m = Doozer::Lib.classify(helper) 
      include Object.const_get(m)
    end
  end
end