require "pathname"
require "base64"
require "yaml"
require "optparse"
require "optparse/pathname"
require "epub/parser"
require "epub/maker"
require "rouge"
require "rouge/lexers/fluentd"

module Pirka
  class App
    class Highlight
      def initialize
        @library_dirs = [
          Pathname(Dir.home)/".config/pirka/codelist",
          Pathname(__dir__)/"../data"
        ]
        @library_path = nil
      end

      # @todo Handle multiple renditions
      def run(argv)
        parse_optoins! argv

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

      # @todo Extract codelist as a library class
      def find_library(unique_identifier, modified)
        return YAML.load_file(@library_path.to_path) if @library_path

        ext = ".yaml" # @todo Extract and use constant or configuration
        @library_dirs.each {|dir|
          # @todo Extract method to calcurate file name
          candidate = (dir/Base64.urlsafe_encode64("#{unique_identifier}@#{modified}")).sub_ext(ext)
          if candidate.file?
            return YAML.load_file(candidate.to_path)
          end
          # @todo Consider the case only the unique identifier is the same
        }
      end

      # @todo Consider descendant elements of code
      def highlight_contents(epub, library)
        need_save = []

        formatter = Rouge::Formatters::HTML.new(wrap: false)

        # @todo Refactor
        dummy_origin = Addressable::URI.parse('file:///')
        css_path = "pirka/style.css" # @todo Avoid overwriting existing file other than Pirka's

        library["codelist"].each_pair do |cfi_string, lang|
          cfi = EPUB::Parser::CFI.parse(cfi_string)
          item, elem = find_item_and_element_from_epub_by_cfi(epub, cfi)
          doc = elem.document
          lexer = Rouge::Lexers.const_defined?(lang) ?
                    Rouge::Lexers.const_get(lang) :
                    Rouge::Lexer.guess(source: elem.content)
          next unless lexer # @todo warn
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
      def parse_optoins!(argv)
        parser = OptionParser.new {|opt|
          opt.on "-l", "--library=FILE", "library file", Pathname do |path|
            @library_path = path
          end
        }
        parser.order! argv
      end

      # @todo Move to EPUB Parser
      def find_item_and_element_from_epub_by_cfi(epub, cfi)
        path_in_package = cfi.paths.first
        step_to_itemref = path_in_package.steps[1]
        itemref = epub.spine.itemrefs[step_to_itemref.step / 2 - 1]

        doc = itemref.item.content_document.nokogiri
        path_in_doc = cfi.paths[1]
        current_node = doc.root
        path_in_doc.steps.each do |step|
          if step.element?
            current_node = current_node.element_children[step.value / 2 - 1]
          else
            element_index = (step.value - 1) / 2 - 1
            if element_index == -1
              current_node = current_node.children.first
            else
              prev = current_node.element_children[element_index]
              break unless prev
              current_node = prev.next_sibling
              break unless current_node
            end
          end
        end

        return itemref.item, current_node
      end
    end

    APPS["highlight"] = Highlight
  end
end
