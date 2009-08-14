""" 
Drawing
name, path w/ symbols, options={controller, action, status, formats, app=>HelloWorld.new}

Name - This is the symbol you name your route. Urls generation is mapped to this key.
Path - This is the url path. May contain token symbols which are exposed to the controller
Options - 
  controller, 
  action, 
  status, 
  formats=>[:xml, json, etc]

Supports the following conventions:
root      ''             :controller=>'something'
articles  '/articles'     :controller=>'article', :action=>'list'
article   '/article/:id'  :controller=>'article', :action=>'show'

Formats
Adding formats symbolzes automatically creates new routes for the formats symbols provided. 
The appropriate content-type is returned with the response.
You can access the format with @format in your controllers.
Supported formats are: :json, :js, :xml, :rss
All routes default to :html format

Example:
  
  map.add :format_example, '/format_example', {:controller=>'index', :action=>'format_example', :status=>200, :formats=>[:json, :xml]}
  
  Automatically creates routes for :html, :json, and :xml with the appropriate content types
  
  :html format (default)
  map.add :format_example, '/format_example', {:controller=>'index', :action=>'format_example', :status=>200} 
  :json format
  map.add :format_example_json, '/format_example.json', {:controller=>'index', :action=>'format_example', :status=>200}
  :xml formate
  map.add :format_example_xml, '/format_example.xml', {:controller=>'index', :action=>'format_example', :status=>200}
  

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
  map.add :index, '', {:controller=>'index', :action=>'index'}
  map.add :index_with_token, '/:token', {:controller=>'index', :action=>'index_with_token', :status=>200}
  map.add :format_test, '/format_test/:id/:name', {:controller=>'index', :action=>'format_test', :status=>200, :formats=>[:xml, :json]}
  map.add :recent, '/recent', {:controller=>'index', :action=>'recent', :status=>200, :formats=>[:rss]}

end