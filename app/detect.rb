require "optparse"
require "optparse/pathname"
require "epub/parser"
require "epub/cfi"
require "epub/searcher"
require "rouge"
require "rouge/lexers/fluentd"
require "pirka/library"

module Pirka
  class App
    class Detect
      PROGRAM_NAME = "detect"

      def initialize
        @library_path = nil
        @lbirary_dir = nil
        @interactive = false

        @available_lexers = Rouge::Lexer.all.sort_by(&:tag).each_with_object({}).with_index {|(lexer, lexers), index|
          lexers[(index + 1).to_s] = lexer
        }
        @lexers_display = @available_lexers.collect {|(index, lexer)|
          option = "#{index}) #{lexer.title}"
          option << "(#{lexer.aliases.join(', ')})" unless lexer.aliases.empty?
          option
        }.join("  ")
        @commands = ["s) skip", "q) quit", "c) show code", "o) show options"].join("  ")
      end

      def run(argv)
        parse_options! argv

        epub_path = argv.shift
        raise ArgumentError, 'Specify EPUB file' unless epub_path

        begin
          # @todo Make this optional
          require 'epub/maker/ocf/physical_container/zipruby'
          EPUB::OCF::PhysicalContainer.adapter = :Zipruby
        rescue LoadError
        end
        epub = EPUB::Parser.parse(epub_path)
        $stderr.puts "Detecting code from \"#{epub.title}\""

        codelist = {}
        library = Library.new(directory: @library_dir)
        library.metadata["Release Identifier"] = epub.release_identifier
        library.metadata["title"] = epub.title
        catch do |quit|
          EPUB::Searcher.search_element(epub, css: 'code').each do |result|
            item = result[:itemref].item
            if @interactive
              catch do |skip|
                show_item item
                show_code result[:element]
                show_options
                show_commands
                i = ask

                while true
                  case i
                  when "s"
                    throw skip
                  when "q"
                    throw quit
                  when "c"
                    show_item item
                    show_code(result[:element])
                    show_options
                    show_commands
                    i = ask
                  when "o"
                    show_options
                    show_commands
                    i = ask
                  else
                    lexer = @available_lexers[i]
                    unless lexer
                      i = ask
                      next
                    end
                    library.codelist[result[:location]] = {"language" => lexer.tag}
                    break
                  end
                end
              end
            else
              library.codelist[result[:location]] = ({
                "language" => nil,
                "item" => result[:itemref].item.entry_name,
                "code" => result[:element].content
              })
            end
          end

          library.save(@library_path)
        end
      end

      # @todo Extract to library
      def determine_identifier(epub)
        Base64.urlsafe_encode64(epub.release_identifier)
      end

      private

      def parse_options!(argv)
        parser = OptionParser.new {|opt|
          opt.on "-i", "--interactive" do
            @interactive = true
          end
          opt.on "-l", "--library=FILE", "File to save library data", Pathname do |path|
            @library_path = path
          end
          opt.on "-d", "--directory=DIRECTORY", "Directory to save library data", Pathname do |path|
            @library_dir = dir
          end
        }
        parser.order! argv
      end

      def show_item(item)
        $stderr.puts
        $stderr.puts item.entry_name
      end

      def show_code(code)
        $stderr.puts
        $stderr.puts code.content
        $stderr.puts
      end

      def show_options
        $stderr.puts @lexers_display
      end

      def show_commands
        $stderr.puts @commands
      end

      def ask
        $stderr.print "Which language?  "
        $stdin.gets.chomp
      end
    end

    APPS[Detect::PROGRAM_NAME] = Detect
  end
end
