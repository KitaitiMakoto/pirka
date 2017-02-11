require "helper"
require "yaml"
require "pirka/library"
require "epub/parser/cfi"

class TestLibrary < Test::Unit::TestCase
  def setup
    @library = Pirka::Library.new
    @library.metadata["Release Identifier"] = "abc"
    @library.metadata["title"] = "abc"
    @library.codelist[EPUB::CFI("/6/30!/4/2/58/2")] = {"language" => "Nginx"}
    @library.codelist[EPUB::CFI("/6/31!/4/2/56/2")] = {"language" => "Nginx"}
    @library.codelist[EPUB::CFI("/6/30!/4/2/56/2")] = {"language" => "Nginx"}
    @yaml = <<EOY
---
Release Identifier: abc
title: abc
codelist:
  epubcfi(/6/30!/4/2/56/2):
    language: Nginx
  epubcfi(/6/30!/4/2/58/2):
    language: Nginx
  epubcfi(/6/31!/4/2/56/2):
    language: Nginx
EOY
  end

  def test_each_iterates_over_list_in_order_of_cfi
    cfis = %w[/6/30!/4/2/56/2
              /6/30!/4/2/58/2
              /6/31!/4/2/56/2]
    i = 0
    @library.each do |(cfi, _)|
      assert_equal cfi.to_s, cfis[i]
      i += 1
    end
  end

  def test_each_returns_enumerator
    assert_equal %w[/6/30!/4/2/56/2
                    /6/30!/4/2/58/2
                    /6/31!/4/2/56/2],
                 @library.each.collect {|(cfi, _)| cfi.to_s}
  end

  def test_to_yaml
    expected = YAML.load(@yaml)
    actual = YAML.load(@library.to_yaml)
    assert_equal expected, actual
  end
end
