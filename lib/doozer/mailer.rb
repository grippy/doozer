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
  class Mailer
    
    # @params variable which is a symbolized hash of all querystring values
    attr_accessor :params

    # @render_args variable containing a hash of values to use while rendering the request
    attr_accessor :render_args

    include Doozer::Util::Logger
    include Doozer::ViewHelpers

    self.class_inheritable_accessor :require_view_helpers

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

    # def initialize(args={})
    # 
    #   #holds all variables for template binding
    #   #@view={};
    #   
    #   #set up default render_args
    #   #@render_args = {:layout=>nil, :view=>nil, :text=>nil}
    #   #render_args_init()
    # 
    # end
    
    def self.send(action, args={})
      puts "sending..."
      
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
          @view[:timestamp] = "<!-- rendered: #{Time.now()} / env: #{rack_env} -->"
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
    
    # Sequel ORM db connection
    def db
      Doozer::Configs.db_conn
    end
    
    # Global teardown called at the end of every request. Hooks ORM.teardown
    def finished!
      Doozer::ORM.after_request if Doozer::Configs.orm_loaded
    end

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
      view = @route.view.to_sym
      layout = (@route.layout.kind_of? String) ? @route.layout.to_sym : @route.layout
      render({
        :view=>view,
        :layout=>layout
      })
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
      view = ERB.new("Missing view for #{@route.view_path}") if view.nil?
      @render_args[:view] = view
    end
  end
end  