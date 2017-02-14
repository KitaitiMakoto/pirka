module Pirka
  class App
    module Subcommand
      # @param [Config]
      def initialize(config)
        @config = config
      end

      private

      def parse_options!(argv)
        parser = OptionParser.new {|opt|
          opt.program_name = "#{opt.program_name} [global options] #{self.class::PROGRAM_NAME}"
          opt.banner = <<EOB
#{DESCRIPTION}

Usage: #{opt.program_name} [options] #{self.class::ARGS}
EOB
          yield opt
        }
        parser.order! argv
      end
    end
  end
end
