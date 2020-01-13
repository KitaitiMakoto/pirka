require "pirka"

module Pirka
  class App
    module Subcommand
      include GetText

      bindtextdomain TEXT_DOMAIN

      class << self
        def included(base)
          APPS[base::PROGRAM_NAME] = base
          base.extend GetText
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
          usage = "Usage: %{program_name} [options] %{subcommand_name}" % {program_name: opt.program_name, subcommand_name: self.class::PROGRAM_NAME}
          usage << " " << self.class::ARGS.join(" ") if self.class.const_defined?(:ARGS)

          opt.program_name = "%{program_name} [options] %{subcommand_name}" % {program_name: opt.program_name, subcommand_name: self.class::PROGRAM_NAME}
          opt.banner = <<EOB % {description: self.class::DESCRIPTION, usage: usage}
%{description}

%{usage}
EOB
          yield opt if block_given?
        }
        parser.order! argv
      end
    end
  end
end
