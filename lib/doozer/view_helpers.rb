require 'digest/sha1'

module Doozer
  
  # ViewHelpers which are included in Controllers and Partials
  module ViewHelpers
    
    # Returns a url from a hash of options. Expects option keys as symbols.
    #
    # :name - the route.name to parse additional options with
    #
    # :base_url - the base url of the request
    #
    # => route tokens are replace the key/values pairs in the options. if a route token is found in the options it is replaced with a 'MISSING-key' string.
    #
    # => all remaining options are added as key=value query string parameters
    #
    # You can also pass a opt as a string which just passed it through.
    #
    def url(opt)
      url = ''
      if opt.kind_of? Hash
        # name (if present) trumps controller/action (if present)
        if opt[:name]
          # TODO: this needs to be only in dev mode
          name = opt.delete(:name)
          route = Doozer::Routing::Routes::get_by_name(name)
          return "MISSING-ROUTE-for-name-#{name}" if route .nil?
          url = "#{route.path}"

          # we need to swap out the tokens here and account for formats on the end of the path
          tokens = route.tokens
          tokens.last.gsub!(Regexp.compile("\.#{route.format.to_s}$"), '') if route.format != :html if not route.tokens.empty?
          tokens.each { |token|
            val = opt[token.to_sym]
            if val
              opt.delete(token.to_sym)
            else  
              val = "MISSING-#{token}" 
            end
            url.gsub!(/:#{token}/, val.to_s)
          }
        end

        # set base_url
        host = ""
        if opt[:base_url]
          host = opt.delete(:base_url)
        end
        # add qs pairs
        if not opt.empty?
          url += "?#{hash_to_qs(opt)}"
        end
        url = "#{host}#{url}"
      elsif opt.kind_of? String
        url = "#{opt}"
      end
      return url
    end
    
    # Creates an html anchor tag.
    #
    # text - the text of the anchor tag
    # 
    # opt - a hash of options which are passed to url(opt)
    #
    # prop - a hash of anchor tag attributes to add to the link
    def link(text='', opt={}, prop={})
      "<a href=\"#{url(opt)}\"#{hash_to_props(prop)}>#{text}</a>"
    end
    
    # Creates an img tag.
    #
    # path - the src of the image tag
    #
    # prop - a hash of image tag attributes
    def img(path, prop={})
      path = timestamp_path(path)
      "<img src=\"#{path}\"#{hash_to_props(prop)} />"
    end
    
    # Creates a stylesheet link tag.
    #
    # path - the href of the link tag
    #
    # prop - a hash of link tag attributes.
    #
    # => Defaults to :rel=>'stylesheet', :type=>'text/css', :media=>'all'
    def stylesheet(path, prop={})
      #<link rel="stylesheet" type="text/css" media="all" href="/css/style.css" />
      path = timestamp_path(path)
      prop[:rel] = 'stylesheet' if prop[:rel].nil?
      prop[:type] = 'text/css' if prop[:type].nil?
      prop[:media] = 'all' if prop[:media].nil?
      "<link #{hash_to_props(prop)} href=\"#{path}\" />"
    end

    # Creates a link tag for feeds.
    #
    # opt - a hash of options which are passed to url(opt)
    #
    # prop - a hash of link tag attributes.
    #
    # => Example: :rel=>'alternate', :type=>'application/rss+', :media=>'all'
    def feed(opt={}, prop={})
      "<link #{hash_to_props(prop)} href=\"#{url(opt)}\" />"
    end

    # Creates a script tag.
    #
    # path - the src of the javascript tag
    #
    # prop - a hash of script tag attributes.
    #
    # => Defaults to: :type=>'text/javascript'
    def javascript(path, prop={})
      path = timestamp_path(path)
      prop[:type] = 'text/javascript' if prop[:type].nil?
      "<script #{hash_to_props(prop)} src=\"#{path}\"></script>"
    end

    # Creates metatags
    #
    # retuns a differnt metatag for each key/value added to @view[:meta] hash. See Doozer::Controller#meta for adding examples.
    def metatags
      #loop all metatags here...
      out=[]
      @view[:meta].each{ | key, value | 
        out.push("""<meta name=\"#{key.to_s}\" content=\"#{h(value)}\" />
                """)
      }
      out.join("")
    end

    # Creates an authtoken form element
    #
    # By default, all post requests expect this value to be present unless overrided with Doozer::Controller#after_initialize
    #
    # You can customize the elemement id by passing arg[:id] to the method.
    #
    # The value contains an checksum of the app_name and cookie sid
    def authtoken(args={})
      id = args[:id] if args[:id]
      "<input type=\"hidden\" id=\"#{id}_authtoken\" name=\"_authtoken\" value=\"#{generate_authtoken(@request.cookies['sid'])}\" />"
    end

    # Turns a hash of key/value pairs in to a key1="value1" key2="value2" key3="value3"
    def hash_to_props(opt={})
      props=[]
      opt.each { | key, value | 
        props.push("#{key.to_s}=\"#{value}\"")
      }
      return " #{props.join(" ")}" if props.length > 0
      return ""
    end

    # Turns a hash of key/value pairs in querystring like key1=value%201&key2=value2&key3=value3
    #
    # All values are CGI.escaped for output
    def hash_to_qs(opt={})
      props=[]
      opt.each { | key, value | 
        props.push("#{key.to_s}=#{CGI::escape(value.to_s)}") 
      }
      props.join("&")
    end    
    
    # Safe encodes a string by entity encoding all less then and greater then signs
    #
    def h(s)
      s.gsub!(/&/,'&amp;')
      s.gsub!(/</,'&lt;')
      s.gsub!(/>/,'&gt;')
      return s
    end
    
    # Returns the base url configured in app.yml
    #
    def base_url
      Doozer::Configs.base_url
    end

    # Returns the env setting the application was loaded under (:development, :deployment, or :test)
    #
    def rack_env
      Doozer::Configs.rack_env
    end

    # Returns the app name configured in app.yml
    #
    def app_name
      Doozer::Configs.app_name
    end

    # Returns the app path the application was loaded in. This defaults to the path all scripts were executed from. In general, this is the root of your project directory unless specified otherwise.
    #
    def app_path
      Doozer::Configs.app_path
    end
    
    # Returns the ip address of the server
    # 
    # Automatically accounts for proxied requests and returns HTTP_X_FORWARDED_FOR if present.
    def ip
      if addr = @env['HTTP_X_FORWARDED_FOR']
        addr.split(',').last.strip
      else
        @env['REMOTE_ADDR']
      end
    end

    # Returns the domain name of the request
    #
    def server_name
      @env['SERVER_NAME']
    end

    # Returns the request path
    #
    def path
        @env['REQUEST_PATH']
    end

    # Test if this person has a session with keys in it...
    def session?
      @session.empty?
    end

    private
    def timestamp_path(path)
      # p Doozer::Configs.rack_env
      return path if Doozer::Configs.rack_env == :deployment
      if path.index('?').nil?
        path = "#{path}?#{@bust_key}"
      else
        path = "#{path}&#{@bust_key}"
      end
    end
    
    ## check to see if form authtoken matches the one expected
    ## phrase defaults to 'sid' which the default used for form authtokens
    def authtoken_matches?(token, phrase=nil)
      phrase = @request.cookies['sid'] if phrase.nil?
      token == generate_authtoken(phrase)
    end
    
    def generate_authtoken(phrase)
      Digest::SHA1.hexdigest("--#{app_name}--#{phrase}--")
    end

  end
end