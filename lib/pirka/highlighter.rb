require "rouge"
require "rouge/lexers/fluentd"

module Pirka
  class Highlighter
    include GetText

    bindtextdomain TEXT_DOMAIN

    def markup(element, lang)
      # noop
    end

    class Middleware
      class Rouge
        FORMATTER = ::Rouge::Formatters::HTML.new

        def initialize(highlighter, formatter: FORMATTER)
          @highlighter = highlighter
          @formatter = formatter
        end

        def markup(element, lang)
          @highlighter.markup(element, lang)
          lexer = ::Rouge::Lexer.find(lang) || ::Rouge::Lexer.guess(source: element.content)
          unless lexer
            warn _("Cannot find lexer for %{lang}") % {lang: lang}
            return
          end
          element.inner_html = @formatter.format(lexer.lex(element.content)) # @todo Consider the case `element` has descendants
        end
      end

      class ClassName
        ATTR_NAME = "class"
        ATTR_SEPARATOR = /\s+/
        CLASS_NAME = "pirka"

        def initialize(highlighter, class_name: CLASS_NAME)
          @highlighter = highlighter
          @class_name = class_name
        end

        def markup(element, lang)
          @highlighter.markup element, lang
          class_names = (element[ATTR_NAME] || "").split(ATTR_SEPARATOR)
          return if class_names.include? @class_name
          class_names << @class_name
          element[ATTR_NAME] = class_names.join(" ")
        end
      end

      class LineNum
        def initialize(highlighter, params = {})
          @highlighter = highlighter
          @selector = params["selector"]
          raise _("selector param not specified") unless @selector
        end

        def markup(element, lang)
          nums = element.search(@selector)
          nums.each(&:unlink)
          @highlighter.markup element, lang
          return if nums.empty?
          element.inner_html = element.inner_html.lines.collect.with_index {|line, index|
            num = nums[index].to_xml
            if line.length > 1
              line[0..0] << num << line[1..-1]
            else
              num << line
            end
          }.join
        end
      end

      class TextLineNum
        def initialize(highlighter, params = {})
          @highlighter = highlighter
          @width = params["width"]
        end

        def markup(element, lang)
          lines = []
          nums = []
          element.content.each_line do |line|
            nums << line[0, @width]
            lines << line[@width..-1]
          end
          element.inner_html = lines.join
          @highlighter.markup element, lang
          element.inner_html = element.inner_html.lines.collect.with_index {|line, index|
            nums[index] << line
          }.join
        end
      end
    end
  end
end
