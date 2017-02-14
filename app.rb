require "optparse"
require "pirka/config"

module Pirka
  class App
    DESCRIPTION = "Pirka highlights source code syntax in EPUB files"
    APPS = {}

    def initialize
      @config = nil
      @tmp_opts = {
        "additional_directories" => []
      }
    end

    def run(argv)
      parse_options! argv
      app = APPS[argv.first] ? APPS[argv.shift] : Highlight
      app.new(@config).run(argv)
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
        opt.on "-c", "--config=FILE", "Config file. Defaults to #{Config.filepath}", Pathname do |path|
          @config = Config.load_file(path)
        end
        opt.on "-s", "--data-home=DIRECTORY", "Directory to *SAVE* library data", Pathname do |path|
          @tmp_opts["data_home"] = path
        end
        opt.on "-d", "--directory=DIRECTORY", "Directory to *SEARCH* library data.", "Specify multiple times to add multiple directories.", Pathname do |path|
          @tmp_opts["additional_directories"] << path
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
      @config ||= Config.new
      @config.data_home = @tmp_opts["data_home"] if @tmp_opts["data_home"]
      @config.additional_directories = @tmp_opts["additional_directories"] unless @tmp_opts["additional_directories"].empty?
    end
  end
end

require_relative "app/highlight"
require_relative "app/detect"
require_relative "app/update"
