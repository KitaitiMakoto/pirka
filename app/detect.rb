require "optparse"
require "epub/parser"
require "epub/cfi"
require "epub/searcher"
require "rouge"
require "rouge/lexers/fluentd"

module Pirka
  class App
    class Detect
      def initialize
        # @todo Define and use class for code list
        @library_dirs = [
          Pathname(Dir.home)/".config/pirka/codelist",
          Pathname(__dir__)/"../data"
        ]
        @library_path = nil
        @interactive = false

        class_prefix = "Rouge::Lexers::"
        @available_lexers = Rouge::Lexer.all.each_with_object({}).with_index {|(lexer, lexers), index|
          lexers[(index + 1).to_s] = lexer.to_s.sub(class_prefix, "")
        }
        @lexers_display = @available_lexers.collect {|(index, lexer)|
          "#{index}) #{lexer}"
        }.join(" ")
        @commands = "s) skip q) quit c) show code again o) show options again"
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
        $stderr.puts "Start detecting code from \"#{epub.title}\""

        codelist = {}
        catch do |quit|
          EPUB::Searcher.search_element(epub, css: 'code').each do |result|
            if @interactive
              catch do |skip|
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
                    codelist[result[:location].to_fragment] = lexer
                    break
                  end
                end
              end
            else
              codelist[result[:location].to_fragment] = "Show below and choose language from #{@available_lexers.values.join(", ")}\n#{result[:element].content}"
            end
          end
        end

        puts determine_identifier(epub)
        output = {
          "Release Identifier" => epub.release_identifier,
          "title" => epub.title,
          "creators" => epub.metadata.creators.join(", "),
          "identifiers" => epub.metadata.identifiers.collect {|identifier|
            obj = {"content" => identifier.content}
            obj["scheme"] = identifier.schem if identifier.scheme
            obj
          },
          "codelist" => codelist
        }
        print output.to_yaml
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
        }
        parser.order! argv
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

    APPS["detect"] = Detect
  end
end
