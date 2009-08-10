# #!/usr/bin/env ruby
require 'optparse'
@command = nil

opts = OptionParser.new("", 24, '  ') { |opts|
  opts.banner = "Usage: script/test [command]"

  opts.separator ""
  opts.separator "Command options:"
  opts.on("-C", "--command COMMAND", "setup (not implemented yet: unit, functional)") { | c |
      @command = c.downcase.to_sym if c
  }
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.parse! ARGV
}

case @command
  when :setup
    require 'test/setup'
end