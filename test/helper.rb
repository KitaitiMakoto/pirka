require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => error
  abort error.message
end

require 'test/unit'
require "test/unit/notify"

class Test::Unit::TestCase
end
