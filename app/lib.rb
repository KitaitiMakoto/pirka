require "pirka/library"

module Pirka
  class App
    class Lib
      PROGRAM_NAME = "lib"
      DESCRIPTION = "Show library infomation"

      include Subcommand

      def run(argv)
        # show all
        # show remote repos
        # show data dirs
        # show data home
        # show books
        # show book metadata

        no_dir_file_length = Library::SUBDIR_LENGTH + Library::EXT.length
        Library.directories.each do |dir|
          next unless dir.directory?

          dir.each_child do |child|
            if child.to_path.length < no_dir_file_length && child.extname != Library::EXT
              show_info child
              next
            end
            next unless child.directory?
            next unless child.basename.to_path.length == Library::SUBDIR_LENGTH
            child.each_child do |lib|
              next unless lib.extname == Library::EXT
              next unless lib.file?
              show_info lib
            end
          end
        end
      end

      def show_info(path)
        $stdout.puts Library.load_file(path).metadata.to_yaml
        $stdout.puts "library: #{path}"
      end

      private

      def parse_options!(argv)
        super do |opt|
        end
      end
    end
  end
end
