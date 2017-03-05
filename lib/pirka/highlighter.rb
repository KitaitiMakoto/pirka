require "rouge"
require "rouge/lexers/fluentd"

module Pirka
  class Highlighter
    def markup(element, lang)
      # noop
    end

    class Middleware
      class Rouge
        FORMATTER = Rouge::Formatters::HTML.new

        def initialize(highlighter, formatter: FORMATTER)
          @highlighter = highlighter
          @formatter = formatter
        end

        def markup(element, lang)
          @highlighter.markup(element, lang)
          lexer = Rouge::Lexer.find(lang) || Rouge::Lexer.guess(source: element.content)
          unless lexer
            warn "Cannot find lexer for #{lang}"
            return
          end
          element.inner_html = @formatter.format(lexer.lex(element.content)) # @todo Consider the case `element` has descendants
        end
      end
    end
  end
end
