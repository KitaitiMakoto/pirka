require 'rubygems'

require "simplecov"
SimpleCov.start do
  add_filter /test|gems/
end

require 'test/unit'
require "test/unit/notify"
require "pirka"

class Test::Unit::TestCase
end
