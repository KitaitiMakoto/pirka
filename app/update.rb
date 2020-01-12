require "English"
require "pathname"
require "uri"
require_relative "subcommand"

module Pirka
  class App
    class Update
      include GetText

      bindtextdomain TEXT_DOMAIN

      PROGRAM_NAME = "update"
      DESCRIPTION = "Update library files by remote files"

      include Subcommand

      URI = ::URI.parse("https://gitlab.com/KitaitiMakoto/pirka-library.git")

      def run(argv)
        parse_options! argv
        dir = determine_directory(URI)
        if dir.directory?
          update_repository(URI, dir)
        else
          clone_repository(URI, dir)
          $stderr.puts "Library was cloned to:"
          $stdout.puts dir
          @config.additional_directories << dir
          @config.library_repositories << URI
          begin
            @config.save
            $stderr.puts "and added to config file %{config_file}" % {config_file: @config.filepath.to_s.dump}
          rescue Errno::EACCESS => error
            $stderr.puts "Couldn't save config file to %{config_file}" % {config_file: @config.filepath.to_s.dump}
            $stderr.puts error
          end
        end
      end

      # @todo Make more generic
      def determine_directory(uri)
        (Pathname.new(Dir.home)/".local/share/pirka"/uri.host/uri.path[1..-1]).sub_ext("")
      end

      def clone_repository(uri, dir)
        run_command "git clone #{uri} #{dir}"
      end

      # @todo Make more generic
      def update_repository(uri, dir)
        Dir.chdir dir do
          run_command "git fetch origin master && git checkout origin/master"
        end
      end

      def run_command(command)
        $stderr.puts "Executing \`%{command}\`" % {command: command}
        output = `#{command}`
        raise "Failed to execute \`%{command}\`" % {command: command} unless $CHILD_STATUS.success?
        output
      end
    end
  end
end
