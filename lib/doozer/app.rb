module Doozer
  class App
    include Doozer::Util::Logger
    attr_accessor :options

    def initialize(args={})
      @options=args

      # load routes
      load_routes
      
      # load the application models, coontrollers, views, and helpers
      load_files
            
      # attach the file watcher for the mvc/lib/etc in development mode
      load_watcher if Doozer::Configs.rack_env != :deployment
      
      puts "=> Doozer racked up"
    end
    
    # This method is called along the rackup chain and maps the request path to the route, controller, and view for the format type.
    def call(env)
      # p env.inspect
      # [200, {"Content-Type" => "text/html"}, "DOH!!!"]
        path = env["PATH_INFO"]
        # match env.path_info against the route compile
        #p env.inspect
        route = Doozer::Routing::Routes::match(path)
        # p "path: #{path}"
        # p "route: #{route.inspect}"
        app = nil
        
        if not route.nil?
          if route.app.nil?
            extra_params = route.extra_params(path)
            controller_klass = handler(route.controller.to_sym)
            controller = controller_klass.new({:env=>env, :route=>route, :extra_params=>extra_params, :port=>@options[:Port]})
            
            # call after_initialize test for excludes
            #execution_time('controller.after_initialize',:start)
            controller.after_initialize if not controller_klass.after_initialize_exclude.include?(route.action.to_sym)
            #execution_time(nil, :end)
            
            begin

              # call before_filter test for excludes
              #execution_time('controller.before_filter',:start)
              controller.before_filter if not controller_klass.before_filter_exclude.include?(route.action.to_sym)
              #execution_time(nil,:end)
              
              # call the action method
              #execution_time('controller.method(route.action).call',:start)
              controller.method(route.action).call()
              #execution_time(nil,:end)
              
              # call after_filter test for excludes
              #execution_time('controller.after_filter',:start)
              controller.after_filter if not controller_klass.after_filter_exclude.include?(route.action.to_sym)
              #execution_time(nil, :end)
              
              # render controller...
              #execution_time('controller.render_result',:start)
              r = Rack::Response.new(controller.render_result, route.status, {"Content-Type" => route.content_type})
              #execution_time(nil,:end)
              r.set_cookie('flash',{:value=>nil, :path=>'/'})
              r.set_cookie('session',{:value=>controller.session_to_cookie(), :path=>'/'})
              r = controller.write_response_cookies(r)
              
              # finalize the request
              controller.finished!
              controller = nil
              app = r.to_a

            rescue Doozer::Redirect => redirect
              # set the status to the one defined in the route which type of redirect do we need to handle?
              status = (route.status==301) ? 301 : 302
              # check to make sure the status wasn't manually changed in the controller
              status = redirect.status if not redirect.status.nil?
                          
              r = Rack::Response.new("redirect...", status, {"Content-Type" => "text/html", "Location"=>redirect.url})
              # if we get a redirect we need to do something with the flash messages...
              r.set_cookie('flash',{:value=>controller.flash_to_cookie(), :path=>'/'}) # might need to set the domain from config app_name value
              r.set_cookie('session',{:value=>controller.session_to_cookie(), :path=>'/'})
              
              # finalize the request              
              controller.finished!
              controller = nil
              app = r.to_a
            rescue => e
              # finalize the request
              controller.finished!
              controller = nil
              
              if Doozer::Configs.rack_env == :deployment
                logger.error("RuntimeError: #{e.to_s}")
                for line in e.backtrace
                  logger.error("        #{line}")
                end
                logger.error("Printing env variables:")
                logger.error(env.inspect)
                app = [500, {"Content-Type" => "text/html"}, @@errors[500]]
              else
                raise e
              end
            end
          else
            app = route.app.call(env)
          end
        else
          app = [404, {"Content-Type" => "text/html"}, @@errors[404]]
        end
        
        # pass the app through route.middleware_after if defined
        app = route.middleware_after.new(app, {:config=>Doozer::Configs, :route=>route}).call(env) if route.middleware_after
  
        return app
    end
    
    def execution_time(name = nil, point = :start)
      if Doozer::Configs.rack_env == :development
        @execution_time_name = name if name
        @execution_time_start = Time.now().to_f if point == :start
        @execution_time_end = Time.now().to_f if point == :end
        logger.info("Excecution Time: #{@execution_time_name}: #{("%0.2f" % ( (@execution_time_end - @execution_time_start) * 1000).to_f)}ms") if point == :end
      end
    end
    
    # Load all application files for app/helpers/*, app/views/layouts/*, app/views/* and app/controllers/*
    def load_files
      # load models
      load_models
      puts "=> Caching files"
      @@controllers = {}
      @@mailers = {}
      @@layouts={}
      @@views={}
      @@errors={}
      
      # require helper files and include into Doozer::Partial
      helper_files = Dir.glob(File.join(app_path,'app/helpers/*_helper.rb'))      
      helper_files.each {|f|
        require f
        key = f.split("helpers/")[1].gsub(/.rb/,'')
        Doozer::Partial.include_view_helper(key)
      }
      
      # cache contoller classes
      controller_files = Dir.glob(File.join(app_path,'app/controllers/*_controller.rb'))
      # we need to load the application_controller first since this might not be the first in the list...
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
      
      controller_files.each { |f|
        require f 
        key = f.split("controllers/")[1].split("_controller.rb")[0]
        if key.index("_")
          value = key.split('_').each{ | k | k.capitalize! }.join('') 
        else
          value = key.capitalize
        end
        klass_name = "#{value}Controller"
        @@controllers[key.to_sym] = klass_name
        # p "cache controller: #{key.to_sym}"
        
        # importing view helpers into controller
        controller_klass = Object.const_get(klass_name)
        # automatically ads the application helper to the class
        controller_klass.include_view_helper('application_helper')
        controller_klass.include_view_helpers
      }
      
      # cache layout erb's
      layout_files = Dir.glob(File.join(app_path,'app/views/layouts/*.erb'))
      layout_files.each {|f|
        key = f.split("layouts/")[1].split(".html.erb")[0].gsub(/.xml.erb/, '_xml').gsub(/.json.erb/, '_json').gsub(/.js.erb/, '_js').gsub(/.rss.erb/, '_rss').gsub(/.atom.erb/, '_atom')
        results = []
        File.new(f, "r").each { |line| results << line }
        @@layouts[key.to_sym] = ERB.new(results.join(""))
      }
      
      #lood 404 and 500 pages if they exist
      pnf = Doozer::Configs.page_not_found_url
      if pnf
        file = File.join(app_path,"#{pnf}")
        results = []
        File.new(file, "r").each { |line| results << line }
        @@errors[404] = results.join("")
      else
        @@errors[404] = "<html><body>Sorry, this page can't be found.</body></html>"
      end
      ise = Doozer::Configs.internal_server_error_url
      if ise
        file = File.join(app_path,"#{ise}")
        results = []
        File.new(file, "r").each { |line| results << line }
        @@errors[500] = results.join("")
      else
        @@errors[500] = "<html><body>There was an internal server error which borked this request.</body></html>"
      end
      
      @@controllers.each_key { | key |
        # p key.inspect
        files = Dir.glob(File.join(app_path,"app/views/#{key.to_s}/*.erb"))
        files.each { | f |
          #!!!don't cache partials here!!!
          view = f.split("#{key.to_s}/")[1].split(".erb")[0].gsub(/\./,'_')
          # p "check view: #{view}"
          if not /^_/.match( view )
            # p "cache view: #{view}"
            results = []
            File.new(f, "r").each { |line| results << line }
            @@views[key] = {} if @@views[key].nil?
            @@views[key][view.to_sym] = ERB.new(results.join(""))
          end
        }
      }

      mailer_files = Dir.glob(File.join(app_path,'app/mailers/*_mailer.rb'))
      mailer_files.each { |f|
        require f 
        key = f.split("mailers/")[1].split("_mailer.rb")[0]
        if key.index("_")
          value = key.split('_').each{ | k | k.capitalize! }.join('') 
        else
          value = key.capitalize
        end
        klass_name = "#{value}Mailer"
        @@mailers[key.to_sym] = klass_name
        # puts "cache mailer: #{key.to_sym}"
        # importing view helpers into controller
        mailer_klass = Object.const_get(klass_name)
        # automatically ads the application helper to the class
        mailer_klass.include_view_helper('application_helper')
        mailer_klass.include_view_helpers
      }
      
      mail_key = :mail
      mailer_files = Dir.glob(File.join(app_path,"app/views/#{mail_key.to_s}/*.erb"))
      mailer_files.each { | f |
        #!!!don't cache partials here!!!
        view = f.split("#{mail_key.to_s}/")[1].split(".erb")[0].gsub(/\./,'_')
        if not /^_/.match( view )
          # puts "cache view: #{view}"
          results = []
          File.new(f, "r").each { |line| results << line }
          @@views[mail_key] = {} if @@views[mail_key].nil?
          @@views[mail_key][view.to_sym] = ERB.new(results.join(""))
        end
      }
    end
    
    # Load application routes
    def load_routes
      require File.join(app_path, 'config/routes')
    end
    
    # Load all application models in app/models
    def load_models
      puts "=> Loading models"
      Dir.glob(File.join(app_path,'app/models/*.rb')).each { | model | 
        require model 
      }
    end
    
    # Loads the file watcher for all application files while in development mode-only.
    #
    # This allows you to edit files without restarting the app server to pickup new changes.
    def load_watcher
      require 'doozer/watcher'
      
      puts "=> Watching files for changes"
      watcher = FileSystemWatcher.new()
      
      # watcher.addDirectory(File.join(File.dirname(__FILE__),'../doozer/'), "*.rb")
      watcher.addDirectory( app_path + '/app/', "**/*")
      watcher.addDirectory( app_path + '/app', "**/**/*")
      watcher.addDirectory( app_path + '/config/', "*.*")
      watcher.addDirectory( app_path + '/lib/', "*.*")
      watcher.addDirectory( app_path + '/static/', "*.*")
      watcher.addDirectory( app_path + '/static/', "**/**/*")

      watcher.sleepTime = 1
      watcher.start { |status, file|
        if(status == FileSystemWatcher::CREATED) then
            puts "created: #{file}"
            load_files
            Doozer::Partial.clear_loaded_partials
            Doozer::MailerPartial.clear_loaded_partials
        elsif(status == FileSystemWatcher::MODIFIED) then
            puts "modified: #{file}"
            load_files
            Doozer::Partial.clear_loaded_partials
            Doozer::MailerPartial.clear_loaded_partials
            Doozer::Configs.clear_static_files
        elsif(status == FileSystemWatcher::DELETED) then
            puts "deleted: #{file}"
            load_files
            Doozer::Partial.clear_loaded_partials
            Doozer::MailerPartial.clear_loaded_partials
            Doozer::Configs.clear_static_files
        end
      }
      #don't join the thread it messes up rackup threading watcher.join()
      # p watcher.isStarted?
      # p watcher.isStopped?
      # p watcher.foundFiles.inspect
    end
  
    def handler(key)
      return Object.const_get(@@controllers[key])
    end
            
    def app_path
      Doozer::Configs.app_path
    end
    
    def self.controllers
      @@controllers
    end

    def self.layouts
      @@layouts
    end
  
    def self.views
      @@views
    end
  
  end #App
end #Doozer