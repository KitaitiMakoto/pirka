require 'pirka/version'
require "gettext"

module Pirka
  include GetText

  bindtextdomain Gem::Specification.load(File.join(__dir__, "../pirka.gemspec"))
end

require "pirka/library"
require "pirka/config"
require "pirka/highlighter"
