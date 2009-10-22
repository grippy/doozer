DOOZER_GEM_VERSION='0.1.5'

require 'date'
require 'rubygems'

begin
  gem 'doozer', "= #{DOOZER_GEM_VERSION}"
  require 'doozer'
rescue Gem::LoadError
  # "grippy-doozer-#{DOOZER_GEM_VERSION} gem not installed. checking different gem name..."
  begin
    gem 'grippy-doozer', "= #{DOOZER_GEM_VERSION}"
    require 'doozer'
  rescue Gem::LoadError
    raise "grippy-doozer-#{DOOZER_GEM_VERSION} gem not installed"
  end
end