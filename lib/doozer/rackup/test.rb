""" 
  script to bootstrap the doozer/rackup/server.ru in test mode
  since rackup doesn't call Rackup::Builder in test (in rackup this is 'none') mode
  
"""
config = 'doozer/rackup/server.ru'
env = :test
cfgfile = File.read(config)
if cfgfile[/^#\\(.*)/]
  opts.parse! $1.split(/\s+/)
end
ru=[]
ru.push("options = {:Port => 5000, :Host => '127.0.0.1', :AccessLog => []}")
ru.push("app = Rack::Builder.new do")
ru.push("use Rack::CommonLogger")
ru.push(cfgfile)
ru.push("end.to_app") 
ru.push("Rack::Handler::Mongrel.run app, :Port => 5000")
app = eval "Rack::Builder.new {( " + ru.join("\n") + "\n )}.to_app", nil, config