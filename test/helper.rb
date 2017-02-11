require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => error
  abort error.message
end

require "simplecov"
SimpleCov.start

require 'test/unit'
require "test/unit/notify"

class Test::Unit::TestCase
end
