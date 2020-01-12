require 'pirka/version'
require "gettext"

module Pirka
  include GetText

  TEXT_DOMAIN = Gem::Specification.load(File.join(__dir__, "../pirka.gemspec")).name

  bindtextdomain TEXT_DOMAIN
end

require "pirka/library"
require "pirka/config"
require "pirka/highlighter"
