module Doozer  
  # The MailerPartial is really similar to Doozer::Partial.
  class MailerPartial
    attr_accessor :erb
        
    include ERB::Util
    include Doozer::Util::Logger
    include Doozer::ViewHelpers
    
    @@partials={}
    
    def initialize(erb, locals)
      @erb = erb
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

    # This class method lazy loads and caches the erb templates of the requested partials
    def self.partial(file=nil, locals={})
      #p "Class method: Doozer::Partial#partial"
      dir = locals[:view_dir]
      if file.index("/").nil?
        name = "#{dir}/_#{file}" 
      else
        name = "#{file.gsub(/\//,'/_')}"
      end
      load_partial(name) if  @@partials[name].nil?
      erb = @@partials[name]
      if erb
          partial = Doozer::MailerPartial.new(erb, locals)
          partial.bind()
      else
        puts "ERROR => no partial exists for #{file}\n"
      end
    end
    
    def partial(file=nil, locals={})
      locals[:view_dir] = @view_dir if not @view_dir.nil?
      Doozer::MailerPartial.partial(file, locals)
    end
    
    # Load and cache partial ERB template with the given file_name.
    def self.load_partial(name)
      
      file = File.join(Doozer::Configs.app_path,"app/views/#{name}.html.erb")
      results = []
      begin
        File.new(file, "r").each { |line| results << line }
        @@partials[name] = ERB.new(results.join(""))
      rescue
        puts "ERROR => sorry couldn't load partial #{name} (#{file})"
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