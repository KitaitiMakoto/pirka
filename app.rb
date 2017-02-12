require "optparse"

module Pirka
  class App
    DESCRIPTION = "Pirka highlights source code syntax in EPUB files"
    APPS = {}

    def run(argv)
      parse_options! argv
      app = APPS[argv.first] ? APPS[argv.shift] : Highlight
      app.new.run(argv)
    end

    private

    def parse_options!(argv)
      parser = OptionParser.new {|opt|
        opt.version = Pirka::VERSION

        opt.banner = <<EOB
#{DESCRIPTION}

Usage: #{opt.program_name} [global options] [<command>] [options]"
EOB

        opt.separator ""
        opt.separator "Global options:"
        opt.on "-d", "--directory=DIRECTORY", "Directory to save and read library data. Prepended to default directories.", "Specify multiple times to prepend multiple directories.", Pathname do |path|
          Library.additional_directories << path
        end

        opt.separator ""
        opt.separator "Commands:"
        width = APPS.keys.collect(&:length).max
        APPS.each_pair do |command, app|
          opt.separator opt.summary_indent + command.ljust(width) +
                        opt.summary_indent * 2 + app::DESCRIPTION
        end
        opt.separator "If command is ommitted, highlight is used with no option"
      }
      parser.order! argv
    end
  end
end

require_relative "app/highlight"
require_relative "app/detect"
require_relative "app/update"
