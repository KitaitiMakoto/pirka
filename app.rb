require "optparse"

module Pirka
  class App
    APPS = {}

    def run(argv)
      parse_options! argv
      app_name = argv.shift
      app = app_name ? APPS[app_name] : Highlight
      app.new.run(argv)
    end

    private

    def parse_options!(argv)
      parser = OptionParser.new {|opt|
        opt.version = Pirka::VERSION
      }
      parser.order! argv
    end
  end
end

require_relative "app/highlight"
require_relative "app/detect"
