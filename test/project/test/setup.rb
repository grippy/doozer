#--load initializers
require 'doozer/initializer'

#--boot it up
Doozer::Initializer.boot(:test)

#--set root
@root = Dir.pwd

#--load migrations
load=[
  '001_initial_schema'
]

Dir.glob(File.join(@root,'db/0*_*.rb')).each { | file |
  klass = file.split("/").last
  if load.include?(klass.gsub(/\.rb/,""))
    # p klass
    require file
    klass = klass.gsub(/\.rb/,"").split("_")
    parts = []
    klass = klass.slice(1, klass.length).each { | part | 
      parts.push(part.capitalize)
    }
    klass = parts.join('')
    klass = Object.const_get(klass)
    klass.down
    klass.up
  end
}

#--load fixtures
require 'test/fixtures/setup'