# = What is Doozer?
# * A lightweight, ORM agnostic, Rack (http://rack.rubyforge.org) compatible MVC framework.
#
# == Project Inspiration
# * Doozer was initially a project I started working on for Google App Engine. It was eventually abandoned since GAE lacked (at the time and may still) proper support for migrations. I ported some of the code to Ruby mainly to learn the internals of Rack back in December 2008.
# * Some of the more useful Rails conventions and methodologies (mostly the application structure, configuration, nonmenclature, scripts, and a few viewhelper methods).
# * Clustering ala Mongrel::Cluster
#
# == Requirements
# * Ruby < 1.9 (untestested on Ruby 1.9 as of now)
# * Rack (http://rack.rubyforge.org) gem (0.9.1 or 1.0.0)
# * An http server supported by Rack
# * ActiveRecord, DataMapper or Sequel
#
# == Getting Started
# 1. Create a folder called 'test' and checkout Doozer.
# 2. From the root 'test' directory run 'ruby doozer/commands/scaffold.rb' to generate the base application skeleton.
# 3. Fire up the application in development mode=> 'script/clusters -C start'.
# 4. Navigate to http://localhost:9292
#
# == Configuration
# * Doozer is configurable to use an ORM library of your choosing: ActiveRecord, DataMapper, or Sequel.
# * By default, routes are handled by Doozer controllers or you can define other Rack compatible applications which handle specific request paths.
# * Http server of your liking (Mongrel, Thin, Lighttpd, or anything supported by Rack).
# * Multiple appservers.
# * Static directories.
#
# == Useful Scripts
# * Generate an application skeleton. Run 'ruby doozer/commands/scaffold.rb' (see Getting Started).
# * Generate views, controllers, and models (depending on the configured ORM). Run 'script/generate -h' for more info.
# * start/stop/restart your web server(s). Run 'script/clusters -h' for more info.
# * Migrations up or down. 'script/migrate -h'.
# * Tasks. Run 'script/task -h' for more info
# * There is a rudimentary test command which allows you to run your own test suite for your application. Run 'script/test -h' for more info.
#
# == Current limitations:
# * Doozer has no test suite. Tsk-tsk I know. In the works.
# * Right now, it doesn't keep track of migration versions.
# * Magic routes are turned off. These worked at one point. They may work again one day.
# * No way to override a view template from inside an action.