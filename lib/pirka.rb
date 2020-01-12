require 'pirka/version'
require "gettext"

module Pirka
  TEXT_DOMAIN = Gem::Specification.load(File.join(__dir__, "../pirka.gemspec")).name
end

require "pirka/library"
require "pirka/config"
require "pirka/highlighter"
