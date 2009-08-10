require 'doozer/app'

module Doozer
  module Routing
    class Routes
      @@parts=[] # stored as [route.name, route.path]
      @@dict={}  # route hash
      @@cache={} # lookup for matches
      @@magics=[] # hold raw magic routes before processing
      @@inner_apps={} # holds the app dedicated to processing this path
      
      def self.draw(&block)
        # p "draw routes"
        instance_eval(&block) if block_given?

        # init magic routes :conrtoller/:action or just /:action with predefined :controller
        # Routes.init_magic_routes
        
        # sort routes here
        @@parts.sort! do |a, b| a[1].length <=> b[1].length end
        @@parts.reverse!
        p "Routes drawn and sorted..."
        # @@parts.each { | i | p i[1] }
      end
      def self.add(name=nil, path=nil, args=nil)
        # p name
        # p path
        # p args.inspect
        if not name.nil? and not path.nil? and not args.nil?
          args = Routes::init_formats(args)
          formats = args[:formats]
          # p formats.inspect
          for format in formats
            args.delete(:formats)
            if name != :magic
              parts = [name, path, args]
              # p parts.inspect
              args[:format] = format
              route = Doozer::Routing::Route.new(parts)
              # p route.inspect
              @@parts.push([route.name, route.path])
              @@dict[route.name] = route
            else
              p "magic routes init turned off"
              # Routes.magic(parts)
            end
          end
        end
      end
      
      def self.init_formats(args)
        formats = args[:formats]
        formats = [] if formats.nil?
        formats.push(:html) if not formats.include?(:html)
        args[:formats] = formats
        return args
      end
      
      def self.get_by_name(name)
        # p @@dict.inspect
        return @@dict[name]
      end

      def self.match(path)
          # p path
          # p @@cache.inspect
          # return @@dict[@@cache[path]] if @@cache[path]
          for part in @@parts
            route = @@dict[part[0]]
            # p route.inspect
            if route.match(path)
              # Routes.cache_request_path(route, path)
              return route
            end
          end
          return nil
      end
      
      def self.cache_request_path(route,path)
        # p "route cache request path"
        @@cache[path] = route.name
      end
      
      def self.magic(route)
        @@magics.push(route)
      end
      
      def self.init_magic_routes
          @@controllers={}
          controller_files = Dir.glob(File.join(File.dirname(__FILE__),'../app/controllers/*_controller.rb'))
          
          if controller_files.length > 0
            i=0
            for f in controller_files
              break if i==0 and f.index('application_controller.rb')
              if f.index('application_controller.rb')
                controller_files.insert(0, controller_files.delete(f))
                break
              end
              i+=1
            end
          end
          
          controller_files.each {|f|
            require f
            key = f.split("controllers/")[1].split("_controller.rb")[0]
            if key.index("_")
              value = key.split('_').each{ | k | k.capitalize! }.join('') 
            else
              value = key.capitalize
            end
            @@controllers[key.to_sym] = "#{value}Controller"
            # p "cache controller: #{key.to_sym}"
          }
          # p @@controllers.inspect
          # grab all controllers
          routes = []
          dup_lu = {}
          obj = Doozer::Controller
          obj.public_instance_methods.each { | name | dup_lu[name]=''}
          # p dup_lu.inspect
          
          @@magics.each { | route |
            path = route[1]
            if path.index(':controller') and path.index(':action')
              ## loop all controller and then loop all #methods
              @@controllers.each{ |key,value | 
                klass = Object.const_get(value)
                methods = klass.public_instance_methods()
                methods.push('index')
                methods.uniq! # filter duplicate indexes
                methods.each { | val | 
                  if dup_lu[val].nil?
                    controller= route[2][:controller] || key.to_s
                    action = route[2][:action] || val
                    # p "#{controller}##{action}"
                    name = "#{controller}_#{action}".to_sym
                    new_path = path.gsub(/:controller/, controller).gsub(/:action/,action)
                    new_path = new_path.gsub(/\/index/) if new_path.endswith('/index')
                    new_path = "/#{new_path}" if not new_path =~ /^\//
                    add([name, new_path, {:controller=>controller, :action=>action, :status=>200, :formats=>route[2][:formats]}])
                  end
                }
              }
            elsif path.index(':action') and not route[2][:controller].nil?
              ## loop all methods on this controller
              #p "load route controller:" + @@controllers[route[2][:controller].to_sym].inspect
              controller= route[2][:controller]

              klass = Object.const_get(@@controllers[controller.to_sym])
              methods = klass.public_instance_methods()
              methods.push('index')
              methods.uniq! # filter duplicate indexes
              methods.each { | val | 
                if dup_lu[val].nil?
                  action = val
                  # p "#{controller}##{action}"
                  name = "#{controller}_#{action}".to_sym
                  new_path = path.gsub(/:action/,action)
                  new_path = new_path.gsub(/\/index/,'') if new_path =~ /\/index/
                  new_path = "/#{new_path}" if not new_path =~ /^\//
                  
                  # p [name, new_path, {:controller=>controller, :action=>action, :status=>200}].inspect
                  add([name, new_path, {:controller=>controller, :action=>action, :status=>200, :formats=>route[2][:formats]}])
                end
              }
            end
          }
          
          ## make sure to route index to '/'
          ## loop route/methods pairs
          # save new path for action controller
      end
    end

    class Route
      attr_accessor :name, :path, :controller, :action, 
                    :layout, :status, :content_type, :tokens, 
                    :grouping, :app, :format, :view, :view_path
      def initialize(route)
        #p "Doozer::Route#new: #{route}"
        args = route[2]
        @controller = args[:controller]
        @action = args[:action]
        @layout = (args[:layout]) ? args[:layout] : 'default'
        @status = (args[:status]) ? args[:status] : 200
        @app=args[:app]
        @format = (args[:format]) ? args[:format] : :html
        #@content_type = (args[:content_type]) ? args[:content_type] : 'text/html'
        case @format
          when :js
            content_type = 'text/javascript'
          when :xml
            content_type = 'text/xml'
          when :json
            content_type = 'application/json'
          when :rss
            content_type = 'application/rss+xml'
          when :atom
            content_type = 'application/atom+xml'
          else
            content_type = 'text/html'
        end
        @content_type = content_type
        @tokens = []
        path = route[1]
        path = '/' if path == ''
        @path = (@format == :html) ? path : "#{path}.#{format}"
        @name = (@format == :html) ? route[0] : "#{route[0]}_#{format.to_s}".to_sym
        @layout = :none if @format != :html and @layout == 'default'
        
        @view = "#{@action}_#{@format.to_s}"
        @view_path = "#{@controller}/#{@action}.#{@format.to_s}.erb"
        regify()
      end
    
      def regify
        if (@path.index('/'))
          grouping = []
          url = @path.split('/')
          for part in url
              if /^:/.match(part) 
                token = part.gsub(/:/,'')
                # part = '(?P<'+token+'>.)'
                # part = '(\.*)'
                # part = '(\w*)'
                part = '([a-zA-Z0-9,-.%]*)' # this picks up all allowable route tokens (a-zA-Z0-9,-.%)
                @tokens.push(token)
              end
              grouping.push(part)
          end
          out = "^#{grouping.join('/')}"
          @grouping = Regexp.compile(out)
        else
          #handle default index route
          @grouping = Regexp.compile("/")
        end
      end
    
      def match(path)
        # p "#{path} vs #{@path}" 
        # p path =~ @grouping
        #short-circut for root
        return false if path == '/' and @path != '/' #handles root condition
        pass=(path =~ @grouping) == 0 ? true : false
        # p @tokens.inspect if pass
        if @tokens.empty?; pass=false if @path != path; end #handles root condition '/'
        pass=false if path.split('/').length != @path.split('/').length #handles the root condition /:token
        return pass
      end
    
      def extra_params(path)
        hashish = {}
        params = @grouping.match(path)
        i = 1
        for token in @tokens
          hashish[token.to_sym] = params[i]
          i += 1 
        end        
        return hashish
      end
    end
  end
end
