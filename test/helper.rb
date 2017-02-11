require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => error
  abort error.message
end

require "simplecov"
SimpleCov.start do
  add_filter "/test"
end

require 'test/unit'
require "test/unit/notify"

class Test::Unit::TestCase
end
