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
        opt.on "-d", "--directory=DIRECTORY", "Directory to save and read library data. Prepended to default directories. Specify multiple times to prepend multiple directories.", Pathname do |path|
          Library.additional_directories << path
        end
      }
      parser.order! argv
    end
  end
end

require_relative "app/highlight"
require_relative "app/detect"
