module Pirka
  class App
    module Subcommand
      class << self
        def included(base)
          APPS[base::PROGRAM_NAME] = base
        end
      end

      # @param [Config]
      def initialize(config)
        @config = config
      end

      private

      # @todo Consider the case the subcommand has no option
      def parse_options!(argv)
        parser = OptionParser.new {|opt|
          usage = "Usage: #{opt.program_name} [options] #{self.class::PROGRAM_NAME}"
          usage << " " << self.class::ARGS.join(" ") if self::class.const_defined?(:ARGS)

          opt.program_name = "#{opt.program_name} [global options] #{self.class::PROGRAM_NAME}"
          opt.banner = <<EOB
#{self::class::DESCRIPTION}

#{usage}
EOB
          yield opt if block_given?
        }
        parser.order! argv
      end
    end
  end
end
