# load gems
%w(rack erb).each { |dep| require dep } 

# load doozer modules
# %w(doozer/lib doozer/extend doozer/logger doozer/view_helpers doozer/route doozer/partial).each { |dep| require dep }

# autoload all models
# Dir.glob(File.join(File.dirname(__FILE__),'../app/models/*.rb')).each {|f| require f }

module Doozer

  # This is the main Controller class which is inherited by application controllers.
  #
  # Controllers have access to all ViewHelpers.
  class Controller
    
    # @route variable containing the route instance
    attr_accessor :route
    # @env variable passed from the Rack request
    attr_accessor :env
    # @request variable. See Rack request for additional methods. http://rack.rubyforge.org/doc/Rack/Request.html
    attr_accessor :request
    # @params variable which is a symbolized hash of all querystring values
    attr_accessor :params
    # @flash variable containing a hash of strings which are persisted in the flash cookie across the response, next request/response and then removed.
    attr_accessor :flash
    # @session variable containing a hash of strings which are persisted in the session cookie until the browser session expires.
    attr_accessor :session
    # @view variable containing a hash of string which are read from layouts.
    attr_accessor :view
    # @bust_key variable which is appended to img sources and script sources via view_helpers in development mode
    attr_accessor :bust_key
    # @format variable which is a symbol
    attr_accessor :format
    # @port variable holing the port number of the appserver handling the request
    attr_accessor :port
    # @render_args variable containing a hash of values to use while rendering the request
    attr_accessor :render_args

    include Doozer::Util::Logger
    include Doozer::ViewHelpers

    self.class_inheritable_accessor :after_initialize_exclude, :before_filter_exclude, :after_filter_exclude, :require_view_helpers
    
    # Array of actions to exclude from calling after_initialize.
    #
    # Example: self.after_initialize_exclude=[:action_1, :action_2]
    self.after_initialize_exclude=[]

    # Array of actions to exclude from calling before_filter.
    #
    # Example: self.before_filter_exclude=[:action_1, :action_2]
    self.before_filter_exclude=[]

    # Array of actions to exclude from calling after_filter.
    #
    # Example: self.after_filter_exclude=[:action_1, :action_2]
    self.after_filter_exclude=[]

    # Array of actions to exclude from calling require_view.
    #
    # Example: self.require_view_helpers=[:application, :helper_1]
    self.require_view_helpers=[]

    # When a Controller is intialized it expects the following args:
    #
    # args={
    #   :route=>route matched against the request path,
    #   :extra_params=>the route tokens parameterized as a hash,
    #   :port=>the port of the appserver responding to the request
    # }
    #
    # * :extra_params are turned into instance variables so you can access them directly from controller methods and views. In order to keep a small footprint these aren't passed into partial classes.
    # 
    # Example: A route of /admin/post/:id and a request path of /admin/post/8 automatically exposes an instance variable of @id with a value of 8 in your controller.
    #
    # * query params are accessible via @params hash and are parameterized via Rack.

    def initialize(args={})
      @route = args[:route]; @env = args[:env]
      @format = @route.format
      @port = args[:port]

      #init request from env
      @request = Rack::Request.new(@env)
      
      #holds all variables for template binding
      @view={}; @view[:meta]={}
      
      #store flash
      @flash={}; flash_from_cookie()
      
      #store session
      @session={}; session_from_cookie()
            
      #symbolize params
      @params={}; @request.params.each { |key, value| @params[key.to_sym] = value} 
      
      #set bust key
      @bust_key = (rand(1000) * 1024)
      
      # set up default render_args
      @render_args = {:layout=>nil, :view=>nil, :text=>nil}
      render_args_init()
      
      #turn extra params into instance variables...
      args[:extra_params].each { |key, value| self.instance_variable_set("@#{key}".to_sym, value)}
      logger.info("       Params: #{@request.params.inspect}") if not @request.params.nil?
      logger.info("       Extra params: #{args[:extra_params].inspect}") if not args[:extra_params].nil?
    end
    
    # Renders an action with any of the following overridable parameters:
    #
    # args={
    #   :view=>Symbol, String or ERB,
    #   :layout=>Symbol,
    #   :text=>'this is the text to render'
    # }
    #
    # :view - All actions default to a view of views/controller_name/action_name.format.erb which is originated from the route properties.
    #
    # To override this from controller actions, you can pass any of the following:
    #
    # * :view=>:view_name
    #
    #   This assumes the view is in the same controller as the present action.
    #
    # * :view=>'controller_name/action_name'
    #
    #   This renders a view from a the provided controller and action and with the format specified in the route.
    #
    # * :view=>ERB.new('<%=var%> is nice')
    #
    # :layout - All actions default to a layout of views/layouts/default.format.erb
    #
    # To override this from controller actions, you can pass any of the following:
    #
    # * :layout=>:layout_name_format or :none (don't display a layout at all)
    #
    #   There is no need to specify the format for :html formats. 
    #
    #   Example: :layout=>:some_layout (where format equals :html) or :some_layout_json (where format equals :json)
    #
    # :text - Overrides all view rendering options and displays an ERB template with the provided text string. 
    #
    # A layout is rendered unless its overriden or the route was declared without one.
    #
    # To override this from controller actions, you can pass any of the following:
    def render(args={})
      change_layout(args[:layout]) if args[:layout]
      change_view(args[:view]) if args[:view]
      change_view(ERB.new(args[:text])) if args[:text]
      
    end
    
    # This method is called from the appserver controller handler.
    def render_result
        layout = @render_args[:layout]
        view = @render_args[:view]
        if layout.kind_of? Symbol # this handles the layout(:none)
          view.result(binding)
        else
          @view[:timestamp] = "<!-- server: #{@port} / rendered: #{Time.now()} / env: #{rack_env} -->"
          @view[:body] = view.result(binding)
          # layout = @layout if layout.nil? # this handles the layout(:some_other_layout) case for formats
          layout.result(binding)
        end
    end
    
    # A method to render a partial from a controller. Expects a file name and optional local variables. See Partial for more details.
    #
    # By default, the @request variable is appended to locals and available in the partial view. 
    def partial(file=nil, locals={})
      # self.instance_variables.each { | k | 
      #   locals[k.gsub(/@/,'').to_s] = eval(k)
      # }
      # p locals.inspect
      locals[:request] = @request
      Doozer::Partial.partial(file, locals, route=@route)
    end
        
    # Redirect the response object to the tokenized route url with optional query string values
    #
    # The route is passed through the ViewHelpers.url method. See url() for examples.
    def redirect_to(route={}, opts={})
      path = url(route)
      # p "Redirect to: #{path}"
      raise Doozer::Redirect.new(path, opts)
    end

    # Sequel ORM db connection
    def db
      Doozer::Configs.db_conn
    end
    
    # Compile flash keys as name=value array which are stored in the flash cookie. The flash variables are only persisted for one response.
    def flash_to_cookie
      #loop over all flash messages and return as name/value array
      out=[]; @flash.each { |key, value| out.push("#{key}=#{CGI::escape(value.to_s)}") }
      return out
    end

    # Read all the flash cookies and store them in the @flash instance variable
    def flash_from_cookie
      #split name/value pairs and merge with flash
      if @request.cookies
        if @request.cookies["flash"]
          pairs=@request.cookies["flash"].split('&')
          pairs.each{|pair| 
            pair = pair.split('=')
            @flash[pair[0].to_sym]=CGI::unescape(pair[1])
          }
        end
      end
    end

    # Compile session keys as name=value array which are eventually stored as cookies.
    def session_to_cookie
      #loop over all flash messages and return as name/value array
      out=[]; @session.each { |key, value| out.push("#{key}=#{CGI::escape(value.to_s)}") }
      return out
    end

    # Read all the session cookies and store them in the @session instance variable
    def session_from_cookie
      #split name/value pairs and merge with flash
      if @request.cookies
        if @request.cookies["session"]
          pairs=@request.cookies["session"].split('&')
          pairs.each{|pair| 
            pair = pair.split('=')
            @session[pair[0].to_sym]=CGI::unescape(pair[1])
          }
        end
      end
    end
    
    # Method for setting metatags via Controllers. 
    #
    # Pass an options hash to meta and all the keys are turned into metatags with the corresponding values.
    #
    # Example: meta({:description=>'The awesome metatag description is awesome', :keywords=>'awesome, blog, of awesomeness'})
    def meta(opt={})
      @view[:meta]=opt
    end
    
    # DEPRECATED: use render() instead
    def layout(sym)
      raise "Deprecated: Controller#layout; Use render({:layout=>:symbol}) instead"
    end
    
    # Controller hook called after controller#initialize call.
    #
    # By default, this method automatically checks if the authtoken is present for post requests. It throws an error if it's missing or has been tampered with.
    def after_initialize
      # test if request == post and if so if authtoken is present and valid
      if @request.post?
        token=@params[:_authtoken]
        if token
          raise "Doozer Authtoken Tampered With!" if not authtoken_matches?(token)
        else
          raise "Doozer Authtoken Missing! By default, post requests require an authtoken. You can override this by adding the action to the after_initialize_exclude list." if not authtoken_matches?(token)
        end
      end
    end
    
    # Controller hook called before controller#method call
    def before_filter; end
    
    # Controller hook called after controller#method call
    def after_filter; end

    # Include additional view helpers declared for the class.
    #
    # This method automatically appends '_helper' to each required helper symbol
    def self.include_view_helpers
        # importing view helpers into controller
        self.require_view_helpers.each { | sym |
          self.include_view_helper("#{sym.to_s}_helper")
        }
    end

    # Include the app/helpers file_name. Expects helper as a string. 
    #
    # You must pass the full file name if you use this method.
    #
    # Example: self.include_view_helper('application_helper')
    def self.include_view_helper(helper)
        # importing view helpers into controller
        include Object.const_get(Doozer::Lib.classify("#{helper}"))
    end
      
    private
    def render_args_init
      if not [301, 302].include?(@route.status)
        # view = (@format == :html) ? "#{@route.name.to_s}_html".to_sym : @route.
        view = @route.view.to_sym
        layout = (@route.layout.kind_of? String) ? @route.layout.to_sym : @route.layout
        render({
          :view=>view,
          :layout=>layout
        })
      end
    end

    def change_layout(sym)
      if sym == :none
        layout=sym
      else
        #this needs to look up the layout and reset layout to this erb template
        lay = Doozer::App.layouts[sym]
        raise "Can't find layout for #{sym}" if lay.nil?
        layout = lay
      end
      @render_args[:layout] = layout
    end

    def change_view(args)
      if args.kind_of? Symbol
        # implies we're using the same controller as the current controller with a view name of :view_name
        view = Doozer::App.views[@route.controller.to_sym][args]
      elsif args.kind_of? String
        # implies 
        controller = (args.index('/')) ? args.split('/')[0].to_sym : @route.controller.to_sym
        action = (args.index('/')) ? args.split('/')[1] : args
        action = "#{action}_#{@format.to_s}".to_sym
        view = Doozer::App.views[controller][action]
      elsif args.kind_of? ERB
        view = args
      end
      view = ERB.new("Missing view for controller#action") if view.nil?
      @render_args[:view] = view
    end
  end
end  