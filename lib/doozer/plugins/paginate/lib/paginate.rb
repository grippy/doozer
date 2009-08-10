# = Doozer Paginate
# This code was lifted (i mean...ported) from the WillPaginate gem for ActiveRecord with a few modifications.
#
# Not supported by this plugin but in WillPAginate: 
# * Page numbers between 'Previous' and 'Next' links
# * NamedScopes
#
# See http://wiki.github.com/mislav/will_paginate for more details on useage and license.
require "#{PAGINATE_PLUGIN_ROOT}/paginate/collection"
module Paginate
  class << self
    def enable_activerecord
      return if ActiveRecord::Base.respond_to? :paginate
      require "#{PAGINATE_PLUGIN_ROOT}/paginate/finder"
      ActiveRecord::Base.send :include, Paginate::Finder
    end
    def enable_view_helpers
      # return if Doozer::Initializer.respond_to? :paginate
      require "#{PAGINATE_PLUGIN_ROOT}/paginate/view_helpers"
      Doozer::Controller.send :include, Paginate::ViewHelpers
      Doozer::Partial.send :include, Paginate::ViewHelpers
    end
  end
end

# Enable ActiveRecord if it's defined
Paginate.enable_activerecord if defined? ActiveRecord

# Load the View Helpers if Doozer::Initializer is loaded
Doozer::Initializer.before_rackup do | config |
  Paginate.enable_view_helpers
end if defined? Doozer::Initializer
