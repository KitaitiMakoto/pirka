require 'helper'
require 'pirka'

class TestPirka < Test::Unit::TestCase

  def test_version
    version = Pirka.const_get('VERSION')

    assert !version.empty?, 'should have a VERSION constant'
  end

end
