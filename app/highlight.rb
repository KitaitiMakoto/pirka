require "pathname"
require "optparse"
require "optparse/pathname"
require "epub/parser"
require "epub/maker"
require "rouge"
require "rouge/lexers/fluentd"
require_relative "subcommand"

module Pirka
  class App
    class Highlight
      PROGRAM_NAME = "highlight"

      include Subcommand

      DESCRIPTION = _("Highlights source code in EPUB file")
      ARGS = %w[EPUB_FILE]

      DUMMY_ORIGIN = Addressable::URI.parse("file:///")
      CSS_PATH = "pirka/style.css" # @todo Avoid conflict with existing item by other than Pirka
      CSS_CLASS_NAME = "pirka"
      SCOPE = ".#{CSS_CLASS_NAME}"
      THEME = "github"

      def initialize(config)
        super
        @library_path = nil
      end

      # @todo Handle multiple renditions
      def run(argv)
        parse_options! argv

        epub_path = argv.shift
        epub = prepare_epub(epub_path)

        library = find_library(epub)

        css_item = add_css_file(epub)
        need_save = highlight_contents(epub, css_item, library)
        need_save << css_item
        need_save.uniq!
        update_modified_date(epub, Time.now)

        save_file epub, need_save
      end

      # @param [EPUB::Book, EPUB::Book::Features] epub
      # @return [EPUB::Publication::Package::Manifest::Item] item indicating added CSS file
      def add_css_file(epub)
        rootfile_path = DUMMY_ORIGIN + epub.ocf.container.rootfile.full_path
        style = Rouge::Theme.find(THEME).new(scope: SCOPE).render

        epub.package.manifest.make_item {|item|
          item.href = (DUMMY_ORIGIN + CSS_PATH).route_from(rootfile_path)
          # IMPROVEMENT: Want to call item.entry_name = css_path
          item.media_type = 'text/css'
          item.id = CSS_PATH.gsub('/', '-') # @todo Avoid conflict with existing items
          item.content = style
        }
      end

      # @todo Make this optional
      def prepare_epub(path)
        raise ArgumentError, _('Specify EPUB file') unless path
        begin
          require 'epub/maker/ocf/physical_container/zipruby'
          EPUB::OCF::PhysicalContainer.adapter = :Zipruby
        rescue LoadError
        end
        EPUB::Parser.parse(path)
      end

      # @todo Do the best when file for release identifier is not find but for unique identifier found
      def find_library(epub)
        library = @library_path ? Library.load_file(@library_path) :
          Library.find_by_release_identifier(epub.release_identifier)
        unless library
          message_template = _("Cannot find code list %{library_file} for %{release_identifier}(%{epub_file}) in any directory of:\n%{search_dirs}")
                               .encode(__ENCODING__) # Needed for Windows non-ascii environment such as code page 932 a.k.a Windiws-31J a Shift_JIS variant encoding
          message = message_template % {
            library_file: Library.filename(epub.release_identifier),
            release_identifier: epub.release_identifier,
            epub_file: epub.epub_file,
            search_dirs: Library.directories.collect {|path| "- #{path}"}.join("\n")
          }
          raise RuntimeError, message
        end
        library
      end

      # @todo Consider descendant elements of code
      def highlight_contents(epub, css_item, library)
        need_save = []

        highlighter = Highlighter::Middleware::ClassName.new(
          Highlighter::Middleware::Rouge.new(
            Highlighter.new),
          class_name: CSS_CLASS_NAME)
        middleware = library.metadata["middleware"]
        if middleware && !middleware.empty?
          highlighter = middleware.reduce(highlighter) {|highlighter, desc|
            params = desc["params"] || {}
            Highlighter::Middleware.const_get(desc["name"]).new(highlighter, params)
          }
        end

        library.reverse_each do |(cfi, data)|
          lang = data["language"]
          unless lang
            warn _("Language for %{cfi} is not detected") % {cfi: cfi}
            next
          end
          itemref, elem, _ = EPUB::Searcher.search_by_cfi(epub, cfi)
          item = itemref.item
          doc = elem.document

          if data["middleware"] && !data["middleware"].empty?
            additional_highlighter = data["middleware"].reduce(highlighter) {|highlighter, desc|
              params = desc["params"] || {}
              Highlighter::Middleware.const_get(desc["name"]).new(highlighter, params)
            }
            additional_highlighter.markup elem, lang
          else
            highlighter.markup elem, lang
          end

          embed_stylesheet_link doc, item, css_item
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

      def embed_stylesheet_link(doc, item, css_item)
        link = doc.at('#pirka') # @todo Avoid conflict with existing link
        unless link
          item_entry_name = DUMMY_ORIGIN + item.entry_name
          entry_name = DUMMY_ORIGIN + css_item.entry_name
          href = entry_name.route_from(item_entry_name)
          link = Nokogiri::XML::Node.new('link', doc)
          link['href'] = href
          link['type'] = 'text/css'
          link['rel'] = 'stylesheet'
          link['id'] = 'pirka'
          head = (doc/'head').first
          head << link
        end
      end

      private

      # @todo theme
      # @todo CSS file path
      # @todo scope
      def parse_options!(argv)
        super do |opt|
          opt.separator ""
          opt.on "-l", "--library=FILE", _("Library file"), Pathname do |path|
            @library_path = path
          end
        end
      end
    end
  end
end
