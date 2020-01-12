require "optparse"
require "pirka"

gem "epub-parser", ">= #{Pirka::EPUB_PARSER_VERSION}"

module Pirka
  class App
    include GetText

    bindtextdomain TEXT_DOMAIN

    DESCRIPTION = _("Pirka highlights source code syntax in EPUB files")
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
    rescue => error
      if $DEBUG
        abort
      else
        abort error.message
      end
    end

    private

    def parse_options!(argv)
      config_path = Config.filepath

      parser = OptionParser.new {|opt|
        opt.version = Pirka::VERSION

        opt.banner = <<EOB % {description: DESCRIPTION, program_name: opt.program_name}
%{description}

Usage: %{program_name} [global options] [<command>] [options]
EOB

        opt.separator ""
        opt.separator _("Global options:")
        opt.on "-c", "--config=FILE", _("Config file. Defaults to %{config_path}") % {config_path: Config.filepath}, Pathname do |path|
          config_path = path
        end
        opt.on "-s", "--data-home=DIRECTORY", _("Directory to *SAVE* library data"), Pathname do |path|
          @tmp_opts["data_home"] = path
        end
        opt.on "-d", "--directory=DIRECTORY", _("Directory to *SEARCH* library data."), _("Specify multiple times to add multiple directories."), Pathname do |path|
          @tmp_opts["additional_directories"] << path
        end
        opt.on "--debug", _("Set debugging flag") do
          $DEBUG = true
        end

        opt.separator ""
        opt.separator _("Commands:")
        width = APPS.keys.collect(&:length).max
        APPS.each_pair do |command, app|
          opt.separator opt.summary_indent + command.ljust(width) +
                        opt.summary_indent * 2 + app::DESCRIPTION
        end
        opt.separator _("If command is ommitted, highlight is used with no option")
      }
      parser.order! argv
      @config = config_path.file? ? Config.load_file(config_path) : Config.new
      @config.data_home = @tmp_opts["data_home"] if @tmp_opts["data_home"]
      @config.additional_directories = @tmp_opts["additional_directories"] unless @tmp_opts["additional_directories"].empty?

      Library.data_home = @config.data_home
      Library.additional_directories = @config.additional_directories
    end
  end
end

require_relative "app/highlight"
require_relative "app/detect"
require_relative "app/update"
require_relative "app/lib"
