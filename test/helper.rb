require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => error
  abort error.message
end

require "simplecov"
SimpleCov.start do
  add_filter /test|gems/
end

require 'test/unit'
require "test/unit/notify"
require "pirka"

class Test::Unit::TestCase
end
