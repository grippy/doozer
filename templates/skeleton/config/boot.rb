DOOZER_GEM_VERSION='0.1.4'


begin
  require 'date'
  require 'rubygems'
  gem 'doozer', "= #{DOOZER_GEM_VERSION}"
  require 'doozer'
rescue Gem::LoadError
  raise "Doozer #{DOOZER_GEM_VERSION} gem not installed"
end

