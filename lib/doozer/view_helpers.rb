require 'digest/sha1'

module Doozer
  module ViewHelpers

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

          # we need to swap out the tokens here...
          route.tokens.each {|token|
            val = opt[token.to_sym]
            if val
              opt.delete(token.to_sym)
            else  
              val = "MISSING-#{token}" 
            end
            url.gsub!(/:#{token}/, val.to_s)
          }
        end

        # set base _url
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
    
    def link(text='', opt={}, prop={})
      "<a href=\"#{url(opt)}\"#{hash_to_props(prop)}>#{text}</a>"
    end
  
    def img(path, prop={})
      path = timestamp_path(path)
      "<img src=\"#{path}\"#{hash_to_props(prop)} />"
    end
    
    def stylesheet(path, prop={})
      #<link rel="stylesheet" type="text/css" media="all" href="/css/style.css" />
      path = timestamp_path(path)
      prop[:rel] = 'stylesheet' if prop[:rel].nil?
      prop[:type] = 'text/css' if prop[:type].nil?
      prop[:media] = 'all' if prop[:media].nil?
      "<link #{hash_to_props(prop)} href=\"#{path}\" />"
    end

    def feed(opt={}, prop={})
      "<link #{hash_to_props(prop)} href=\"#{url(opt)}\" />"
    end

    def javascript(path, prop={})
      path = timestamp_path(path)
      prop[:type] = 'text/javascript' if prop[:type].nil?
      "<script #{hash_to_props(prop)} src=\"#{path}\"></script>"
    end

    def metatags
      #loop all metatags here...
      out=[]
      @view[:meta].each{ | key, value | 
        out.push("""<meta name=\"#{key.to_s}\" content=\"#{h(value)}\" />
                """)
      }
      out.join("")
    end
    
    def hash_to_props(opt={})
      props=[]
      opt.each { | key, value | 
        props.push("#{key.to_s}=\"#{value}\"")
      }
      return " #{props.join(" ")}" if props.length > 0
      return ""
    end

    def hash_to_qs(opt={})
      props=[]
      opt.each { | key, value | 
        props.push("#{key.to_s}=#{CGI::escape(value.to_s)}") 
      }
      props.join("&")
    end    
    
    def h(s)
      s.gsub!(/</,'&lt;')
      s.gsub!(/>/,'&gt;')
      return s
    end
    
    def base_url
      Doozer::Configs.base_url
    end

    def rack_env
      Doozer::Configs.rack_env
    end

    def app_name
      Doozer::Configs.app_name
    end

    def app_path
      Doozer::Configs.app_path
    end
    
    def ip
      if addr = @env['HTTP_X_FORWARDED_FOR']
        addr.split(',').last.strip
      else
        @env['REMOTE_ADDR']
      end
    end

    def server_name
      @env['SERVER_NAME']
    end

    def path
        @env['REQUEST_PATH']
    end

    def authtoken(args={})
      id = args[:id] if args[:id]
      "<input type=\"hidden\" id=\"#{id}_authtoken\" name=\"_authtoken\" value=\"#{generate_authtoken(@request.cookies['sid'])}\" />"
    end

    # test if this person has a session with keys in it...
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