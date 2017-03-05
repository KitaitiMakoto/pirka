require "rouge"
require "rouge/lexers/fluentd"

module Pirka
  class Highlighter
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
            warn "Cannot find lexer for #{lang}"
            return
          end
          element.inner_html = @formatter.format(lexer.lex(element.content)) # @todo Consider the case `element` has descendants
        end
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
        return class_names.include? @class_name
        class_names << @class_name
        element[ATTR_NAME] = class_names.join(" ")
      end
    end
  end
end
