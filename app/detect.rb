require "optparse"
require "optparse/pathname"
require "epub/parser"
require "epub/cfi"
require "epub/searcher"
require "rouge"
require "rouge/lexers/fluentd"
require "colored"
require_relative "subcommand"

module Pirka
  class App
    class Detect
      include GetText

      bindtextdomain TEXT_DOMAIN

      PROGRAM_NAME = "detect"
      DESCRIPTION = _("Detects source code from EPUB file and generate library file")
      ARGS = %w[EPUB_FILE]

      include Subcommand

      SELECTOR = "code"

      def initialize(config)
        super

        @library_path = nil
        @interactive = false
        @selector = SELECTOR

        @available_lexers = Rouge::Lexer.all.sort_by(&:tag).each_with_object({}).with_index {|(lexer, lexers), index|
          lexers[(index + 1).to_s] = lexer
        }
        initial = nil
        @lexers_display = @available_lexers.collect {|(index, lexer)|
          init = lexer.title[0].upcase
          if initial == init
            option = ""
          else
            option = "\n"
            initial = init
          end
          option << "#{index})".bold << " " << lexer.title
          option << "(#{lexer.aliases.join(', ')})" unless lexer.aliases.empty?
          option
        }.join("  ")
        @commands = {
          "s" => _("skip"),
          "q" => _("quit"),
          "c" => _("show code"),
          "o" => _("show options")
        }.collect {|(key, command)|
          "#{key})".bold << " " << command
        }.join("  ")
      end

      def run(argv)
        parse_options! argv

        epub_path = argv.shift
        raise ArgumentError, _('Specify EPUB file') unless epub_path

        begin
          # @todo Make this optional
          require 'epub/maker/ocf/physical_container/zipruby'
          EPUB::OCF::PhysicalContainer.adapter = :Zipruby
        rescue LoadError
        end
        epub = EPUB::Parser.parse(epub_path)
        $stderr.puts _("Detecting code from \"%{title}\"").encode(__ENCODING__) % {title: epub.title}

        codelist = {}
        library = Library.new
        library.metadata["Release Identifier"] = epub.release_identifier
        library.metadata["title"] = epub.title
        catch do |quit|
          EPUB::Searcher.search_element(epub, css: @selector).each do |result|
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
          path = library.save(@library_path)
          $stderr.puts _("Library file was saved to:")
          $stdout.puts path
        end
      end

      private

      def parse_options!(argv)
        super do |opt|
          opt.separator ""
          opt.on "-i", "--interactive" do
            @interactive = true
          end
          opt.on "-o", "--output=FILE", _("File to save library data"), Pathname do |path|
            @library_path = path
          end
          opt.on "-s", "--selector=SELECTOR", _("CSS selector to detect source code element. Defaults to %{selector}.") % {selector: SELECTOR.dump} do |selector|
            @selector = selector
          end
        end
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
        $stderr.puts
        $stderr.puts @commands
      end

      def ask
        $stderr.print _("Which language?  ")
        $stdin.gets.chomp
      end
    end
  end
end
