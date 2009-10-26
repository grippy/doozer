""" 
Drawing
name, path w/ symbols, options={controller, action, status, formats, optional( layout, app=>HelloWorld.new)}

Name - This is the symbol you name your route. Urls generation is mapped to this key.
Path - This is the url path. May contain token symbols which are exposed to the controller
Options - 
  controller, 
  action, 
  status, 
  formats=>[:xml, json, etc],
  layout
  
Supports the following conventions:
  :root      ''             :controller=>'something'
  :articles  '/articles'     :controller=>'article', :action=>'list'
  :article   '/article/:id'  :controller=>'article', :action=>'show'

Formats
  Adding formats symbols automatically creates new routes for the formats symbols provided. 
  The appropriate content-type is returned with the response.
  You can access the format with @format in your controllers.
  Supported formats are: :json, :js, :xml, :rss, :atom
  All routes default to :html format

Example:
  
  map.add :format_example, '/format_example', {:controller=>'index', :action=>'format_example', :status=>200, :formats=>[:json, :xml]}
  
  Automatically creates routes for :html, :json, and :xml with the appropriate content types

  :html format (default)
  map.add :format_example, '/format_example', {:controller=>'index', :action=>'format_example', :status=>200} 

  :json format
  map.add :format_example_json, '/format_example.json', {:controller=>'index', :action=>'format_example', :status=>200}

  :xml format
  map.add :format_example_xml, '/format_example.xml', {:controller=>'index', :action=>'format_example', :status=>200}

Layouts
  
  All routes use the layouts/default.format.erb view. You can override this by passing the layout symbol in the options hash like this:
  map.add :layout_example, '/layout_example', {:controller=>'index', :action=>'layout_example', :status=>200, :layout=>'other'}
  
View/Layouts with Formats

  If you define non-html formats you need to be aware of a few caveats.
  
  map.add :layout_format_example, 
          '/layout_format_example', 
          {:controller=>'index', :action=>'layout_format_example', :status=>200, :layout=>'other', :formats=>[:json]}
          
  When calling the above route with json format:
    You will need to have a layouts/other.json.erb file along with an index/layout_format_example.json.erb file to render the view

  See Doozer::Controller#render for more examples on how to override this from controllers actions.

Controller/View Helpers
Route url generation is accessible in the following ways:
  Defauls method for generating route urls:
    url({:name=>:some_route ... :key=>'some value'})
  -or-
  Magic helper methods for generating route urls. The param order is taken right from the order of the parsed route tokens.

    route_name_url - default html, no params
    route_name_url(param1, params2)  - default html,  w/ params
    route_name_format_url(param1, params2) - non html w/ params
    
    Example:
      some_route_url
      some_route_json_url(param1, param2, param3)

In addition, you can also wrap the urls with a link tag like this:
  link('anchor text', route_args, link_args)
  Example:
    link('homepage', {:name=>:index}, {:class=>'link_css', :id=>'home'})
    -or-
    link('homepage', index_url, {:class=>'link_css', :id=>'home'})


Not Currently Supported...
  Magic Routes
  This route automatically creates routes for all actions on controller 'something_not_called_fubar'
  fubar/:action :controller=>'something_not_called_fubar'
  This creates routes for all controller actions residing in the application.
  :controller/:action

Additional Rackup Apps
You can create additional rackup apps and assign them to a route

Just require the file here and then instantiate the class when you map the route. 
Make sure the rackup app adheres to the rack spec.

Example:

require 'lib/rackup_upload'
Doozer::Routing::Routes.draw do | map |
  map.add :upload, '', {:controller=>'upload', :action=>'process', :status=>200, :app=>RackupUpload.new}
end
"""

Doozer::Routing::Routes.draw do | map | 
  
          """ 
          :name, 
          :path w/ tokens, 
          :options={:controller, :action, :status, :formats=>[:json, :xml, :js, etc], :app=>Class.new} 
          """
  map.add :index, '', {:controller=>'index', :action=>'index', :status=>200}

end