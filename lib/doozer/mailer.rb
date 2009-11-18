# load gems
%w(rack erb).each { |dep| require dep } 

module Doozer

  # The Mailer class operates in many ways like a Controller.
  #
  # Mailers have access to all ViewHelpers methods.
  # 
  # Mailers can also load partials.
  #
  # Limitations: 
  # - The current send implemntation must be overridden by your application.
  # - Create multipart messages but only handles html content types. No text or attachment capabilities.
  #
  class Mailer
    
    # @controller variable containing the name of the mailer
    attr_accessor :controller
    # @action variable containing the name of the mailer action to deliver
    attr_accessor :action
    # @from variable which contains either a string or list of senders. Example: ['some@email.com', 'Some guy <some@guy.com>']
    attr_accessor :from
    # @to variable which contains either a string or list of recipients. Example: ['some@email.com', 'Some guy <some@guy.com>']
    attr_accessor :to
    # @cc variable which contains either a string or list of recipients which should be cc'd on the email. Example: ['some@email.com', 'Some guy <some@guy.com>']
    attr_accessor :cc
    # @bcc variable which contains either a string or list of recipients which should be bcc'd on the email. Example: ['some@email.com', 'Some guy <some@guy.com>']
    attr_accessor :bcc
    # @subject variable which contains the subject of the mail.
    attr_accessor :subject
    # @date variable which contains the date of the email. Must be a Time object. Defaults to Time.now.
    attr_accessor :date
    # @envelope variable which holds the TMail object for the mail.
    attr_accessor :envelope
    # @message_id variable which holds the unique message identifier of the mail.
    attr_accessor :message_id
    # @charset variable which holds the character set of the mail. Defaults to "ISO-8859-1"
    attr_accessor :charset
    # @render_args variable containing a hash of values to use while rendering the message
    attr_accessor :render_args
    
    include Doozer::Util::Logger
    include Doozer::ViewHelpers

    self.class_inheritable_accessor :require_view_helpers, :view_dir, :layout
    
    # Array of helper methods to include inside the view.
    #
    # Example: self.require_view_helpers=[:application, :helper_1]
    self.require_view_helpers=[]
    
    # Default directory where the views should be looked up for the mail.
    self.view_dir = 'mail'

    # Default mail layout to use for the mail
    self.layout = :default_mail.
    
    # Create a new Mailer object
    # - action: a symbol of the action to call
    # - args: optional list of arguments
    def initialize(action, args={})
      @controller = self.class.to_s
      @action = action
      
      #holds all variables for template binding
      @view={}
      @to = args[:to]
      @from = args[:from]
      @cc = args[:cc]
      @bcc = args[:bcc]
      @subject = args[:subject] || ''
      @date = args[:date] || Time.now()
      @charset = args[:charset] || "ISO-8859-1"
      
      @message_id = "#{DateTime.now().strftime('%Y%m%d%H%M%S')}.#{(rand(1000) * 1024).to_s}"
      @envelope = nil
      @render_args = {:layout=>nil, :view=>nil, :text=>nil}
      render({
        :view=>args[:view] || action,
        :layout=>args[:layout] || mailer_class.layout,
        :text=>args[:text]
      })
      
      # turn the rest of the args into instance variables
      args.delete(:view) if args[:view]
      args.delete(:layout) if args[:delete]
      args.delete(:text) if args[:text]
      args.each { |key, value| self.instance_variable_set("@#{key}".to_sym, value)}
      
    end
    
    # Erb binding
    def bind
      @erb.result(binding)
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
    
    # Call this method to deliver a Mailer#action
    #
    # Arguments
    # - action: The action of the mailer to call passed as a symbol.
    # - args:  The mail arguments to initialize the email with. 
    #           All remaining arguments are turned into instance variables and bound to the view.
    
    # Note: The send mechanism is empty and must be overriden in the calling application.
    def self.deliver(action, args={})
      # puts "deliver.."
      mailer = self.new(action, args)
      mailer.method(action).call()
      mailer.finished! #close the db connections
      mailer.package
      send(mailer)
    end
    
    # The send method must be overriden by the calling class.
    # 
    # => The mailer object passed to this mehod of the instance of the mailer.
    # => You can access the mailer.envelope.encoded (tmail) object which handles all the encoding.
    def self.send(mailer); end

    # This method is called prior to #send and handles the creation of envelope.
    def package
      raise "Missing from address" if self.from.nil?

      begin 
        @envelope = TMail::Mail.new()
      rescue => e
        begin
          require 'tmail'
          @envelope = TMail::Mail.new()
        rescue MissingSourceFile, Gem::LoadError => e
          logger.error("TMail Gem wasn't found. Please install if you want to send mail.")
        end
      end
      
      # http://tmail.rubyforge.org/rdoc/index.html
      @envelope.mime_version = "1.0"
      @envelope.charset = self.charset
      @envelope.message_id = self.message_id
      @envelope.from = [self.from]
      @envelope.to = [self.to] if self.to
      @envelope.cc = [self.cc] if self.cc
      @envelope.bcc = [self.bcc] if self.bcc
      @envelope.date = self.date
      @envelope.subject = self.subject
      
      html = TMail::Mail.new()
      html.body = self.render_result
      html.set_content_type('text','html')
      
      @envelope.parts << html
      @envelope.set_content_type('multipart', 'mixed') # needs to be set last or throws an error
    end
    
    # Call this method to receive the list of only :to addresses. Use this when sending through SMTP.
    def to_address
      out = []; @envelope.to_addrs.each{|a| out.push(a.address)}
      return out
    end

    # Call this method to receive the list of only :from addresses. Use this when sending through SMTP.
    def from_address
      out = []; @envelope.from_addrs.each{|a| out.push(a.address)}
      return out
    end
    
    # Helper method for initializing partials from views.
    def partial(file=nil, locals={})
      locals[:view_dir] = mailer_class.view_dir
      Doozer::MailerPartial.partial(file, locals)
    end
    
    # Renders an action with any of the following overridable parameters:
    #
    # args={
    #   :view=>Symbol, String or ERB,
    #   :layout=>Symbol,
    #   :text=>'this is the text to render'
    # }
    #
    def render(args={})
      change_layout(args[:layout]) if args[:layout]
      change_view(args[:view]) if args[:view]
      change_view(ERB.new(args[:text])) if args[:text]
    end
    
    # This method creates the html part of the mail.
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
    
    # Sequel ORM db connection
    def db
      Doozer::Configs.db_conn
    end
    
    # Global teardown called at the end of every request. Hooks ORM.teardown
    def finished!
      Doozer::ORM.after_request if Doozer::Configs.orm_loaded
    end
    
    # Returns the Mailer object
    def mailer_class
      Object.const_get(self.class.to_s)
    end
    
    private
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
        view = Doozer::App.views[mailer_class.view_dir.to_sym]["#{args.to_s}_html".to_sym]
      elsif args.kind_of? ERB
        view = args
      end
      view = ERB.new("Missing view for goes here") if view.nil?
      @render_args[:view] = view
    end
  end
end  