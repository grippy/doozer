#!/usr/bin/env ruby
require 'rubygems'
require 'doozer'

#--load initializers
# require 'doozer/initializer'

#--boot it up
Doozer::Initializer.boot(env)

#--hookup the logger for production only since the base rackup builder doesn't load it. this avoids double logging in development
use Rack::CommonLogger, Doozer::Configs.logger if Doozer::Configs.rack_env == :deployment

#--map root to doozer
map "/" do
	# use Rack::ShowExceptions
	if Doozer::Configs.rack_env != :deployment
	  use Rack::Reloader, secs=1
	end
	
	use Rack::Static, {:urls => Doozer::Configs.app["static_urls"], :root => "#{Dir.pwd}/#{Doozer::Configs.app["static_root"]}"} if Doozer::Configs.app

	use Rack::Session::Cookie, :key => 'rack.session',
	                           :domain => '',
	                           :path => '/',
	                           :expire_after => 2592000
	
	run Doozer::App.new(args=options)
end

#--stack additional rack apps
begin
	require "#{Dir.pwd}/config/rack"
	stack()
rescue => e
	Doozer::Configs.logger.error(e)
end