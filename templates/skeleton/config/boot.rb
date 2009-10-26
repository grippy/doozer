DOOZER_GEM_VERSION='0.2.5'

require 'date'
require 'rubygems'

begin
  gem 'doozer', "= #{DOOZER_GEM_VERSION}"
  require 'doozer'
rescue Gem::LoadError
  raise "grippy-doozer-#{DOOZER_GEM_VERSION} gem not installed"
end
