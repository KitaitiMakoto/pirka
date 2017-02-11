require "pathname"
require "optparse"
require "optparse/pathname"
require "epub/parser"
require "epub/maker"
require "rouge"
require "rouge/lexers/fluentd"
require "pirka/library"

module Pirka
  class App
    class Highlight
      PROGRAM_NAME = "highlight"

      def initialize
        @library_path = nil
      end

      # @todo Handle multiple renditions
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
        library = find_library(epub.unique_identifier, epub.modified)
        raise RuntimeError, "Cannot find code list for #{epub.release_identifier}(#{epub_path})" unless library

        need_save = add_css_file(epub) + highlight_contents(epub, library)
        need_save.uniq!
        update_modified_date(epub, Time.now)

        save_file epub, need_save
      end

      def add_css_file(epub)
        dummy_origin = Addressable::URI.parse('file:///')
        rootfile_path = dummy_origin + epub.ocf.container.rootfile.full_path
        css_path = "pirka/style.css" # @todo Avoid overwriting existing file other than Pirka's
        theme = "github"
        scope = "code"
        style = Rouge::Theme.find(theme).new(scope: scope).render
        need_save = []

        epub.package.manifest.make_item do |item|
          item.href = Addressable::URI.parse((dummy_origin + css_path).route_from(rootfile_path)) # IMPROVEMENT: Less need to call Addressable::URI.parse explicitly
          # IMPROVEMENT: Want to call item.entry_name = css_path
          item.media_type = 'text/css'
          item.id = css_path.gsub('/', '-') # @todo Avoid conflict with existing items
          item.content = style
          need_save << item
        end

        need_save
      end

      # @todo Do the best when file for release identifier is not find but for unique identifier found
      def find_library(unique_identifier, modified)
        @library_path ? Library.from_file(@library_path) :
          Library.find_by_release_identifier("#{unique_identifier}@#{modified}")
      end

      # @todo Consider descendant elements of code
      def highlight_contents(epub, library)
        need_save = []

        formatter = Rouge::Formatters::HTML.new(wrap: false)

        # @todo Refactor
        dummy_origin = Addressable::URI.parse('file:///')
        css_path = "pirka/style.css" # @todo Avoid overwriting existing file other than Pirka's

        library.codelist.each.reverse_each do |(cfi, data)|
          lang = data["language"]
          unless lang
            warn "Language for #{cfi} is not detected"
            next
          end
          itemref, elem = EPUB::Searcher.search_by_cfi(epub, cfi)
          item = itemref.item
          doc = elem.document
          lexer = Rouge::Lexer.find(lang) || Rouge::Lexer.guess(source: elem.content)
          unless lexer
            warn "Cannot find lexer for #{lang}"
            next
          end
          elem.inner_html = formatter.format(lexer.lex(elem.content)) # @todo Consider the case `elem` has descendants

          link = doc.css('#pirka').first # @todo Avoid conflict with existing link
          unless link
            item_entry_name = dummy_origin + item.entry_name
            entry_name = dummy_origin + css_path
            href = entry_name.route_from(item_entry_name)
            link = Nokogiri::XML::Node.new('link', doc)
            link['href'] = href
            link['type'] = 'text/css'
            link['rel'] = 'stylesheet'
            link['id'] = 'pirka'
            head = (doc/'head').first
            head << link
          end
          item.content = doc.to_xml
          need_save << item
        end

        need_save
      end

      def update_modified_date(epub, time = Time.now)
        modified = epub.modified
        unless modified
          modified = EPUB::Publication::Package::Metadata::Meta.new
          modified.property = 'dcterms:modified'
          epub.package.metadata.metas << modified
        end
        modified.content = time.utc.iso8601

        modified
      end

      def save_file(epub, need_save)
        need_save.each do |item|
          item.save
          epub.package.manifest << item
        end
        epub.package.edit
      end

      private

      # @todo theme
      # @todo CSS file path
      # @todo scope
      def parse_options!(argv)
        parser = OptionParser.new {|opt|
          opt.on "-l", "--library=FILE", "library file", Pathname do |path|
            @library_path = path
          end
        }
        parser.order! argv
      end
    end

    APPS[Highlight::PROGRAM_NAME] = Highlight
  end
end
