require "English"
require "pathname"
require "uri"
require "pirka/library"
require_relative "subcommand"

module Pirka
  class App
    class Update
      include Subcommand

      PROGRAM_NAME = "update"
      DESCRIPTION = "Update library files by remote files"
      ARGS = ""

      URI = ::URI.parse("https://gitlab.com/KitaitiMakoto/pirka-library.git")

      def run(argv)
        parse_options! argv
        ensure_git_command
        dir = determine_directory(URI)
        if dir.directory?
          update_repository(URI, dir)
        else
          clone_repository(URI, dir)
          @config.additional_directories << dir
          @config.save
          $stderr.puts "Library was cloned to:"
          $stdout.puts dir
          $stderr.puts "and added to config file #{@config.filepath.to_s.dump}"
        end
      end

      def ensure_git_command
        raise "Cannot find `git` command" unless system("type", "git")
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
        output = `#{command}`
        $stderr.puts "Executing \`#{command}\`"
        raise "Failed to execute \`#{command}\`" unless $CHILD_STATUS.success?
        output
      end
    end

    APPS[Update::PROGRAM_NAME] = Update
  end
end
