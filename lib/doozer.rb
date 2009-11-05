DOOZER_PATH = File.expand_path(File.dirname(__FILE__))
$:.unshift(DOOZER_PATH) unless $:.include?(DOOZER_PATH)

# load active_support hooks
require File.join(DOOZER_PATH, 'doozer/extend')

module Doozer

  autoload :App,            "doozer/app"
  autoload :Configs,        "doozer/configs"
  autoload :Controller,     "doozer/controller"
  autoload :Initializer,    "doozer/initializer"
  autoload :Lib,            "doozer/lib"
  autoload :Partial,        "doozer/partial"
  autoload :Redirect,       "doozer/redirect"
  
  module Routing
    autoload :Route,        "doozer/route"
    autoload :Routes,       "doozer/route"
  end
  
  module Util
    autoload :Logger,       "doozer/logger"
  end

  module Exceptions
    autoload :Route,        "doozer/exceptions"
  end
  
  autoload :Middleware,                   "doozer/middleware"
  autoload :MiddlewareBeforeDozerApp,     "doozer/middleware"


  autoload :Task,           "doozer/task"
  autoload :ViewHelpers,    "doozer/view_helpers"
  autoload :Version,        "doozer/version"
  
  # Generator methods
  autoload :Generator,      "generator/generator"
end
