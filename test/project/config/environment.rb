# This file is loaded right after orm is initialized and right before app, controllers and models
# place code here which is used throughout the application
puts "=> Loading environment"

Doozer::Initializer.after_orm do | config |
  # require 'doozer/plugins/paginate/init'
end

Doozer::Initializer.before_rackup do | config |
  # p "Before rackup, horray for rackup!"
end