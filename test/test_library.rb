require "helper"
require "yaml"
require "tmpdir"
require "pirka/library"
require "epub/parser/cfi"

class TestLibrary < Test::Unit::TestCase
  def setup
    Pirka::Library.data_home = nil
    Pirka::Library.additional_directories.clear
    @library = Pirka::Library.new
    @library.metadata["Release Identifier"] = "abc"
    @library.metadata["title"] = "abc"
    @library.codelist[EPUB::CFI("/6/30!/4/2/58/2")] = {"language" => "nginx"}
    @library.codelist[EPUB::CFI("/6/31!/4/2/56/2")] = {"language" => "nginx"}
    @library.codelist[EPUB::CFI("/6/30!/4/2/56/2")] = {"language" => "nginx"}
    @fixure_path = "test/fixtures/YWJj.yaml"
    @yaml = <<EOY
---
Release Identifier: abc
title: abc
codelist:
  epubcfi(/6/30!/4/2/56/2):
    language: nginx
  epubcfi(/6/30!/4/2/58/2):
    language: nginx
  epubcfi(/6/31!/4/2/56/2):
    language: nginx
EOY
  end

  def test_load_hash
    actual = Pirka::Library.load_hash(YAML.load(@yaml))
    assert_equal @library.metadata, actual.metadata
    assert_equal @library.each.to_a, actual.each.to_a
  end

  def test_load_file
    actual = Pirka::Library.load_file(@fixure_path)
    assert_equal @library.metadata, actual.metadata
    assert_equal @library.each.to_a, actual.each.to_a
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

  def test_save_to_path_when_path_specified
    Dir.mktmpdir "pirka" do |dir|
      path = Pathname.new(dir)/"arbitral-filename.yaml"
      @library.save(path)
      data = YAML.load_file(path.to_path)
      codelist = data.delete("codelist")
      assert_equal @library.metadata, data

      expected_codelist = @library.each.with_object({}) {|(cfi, value), list|
        list[cfi.to_fragment] = value
      }
      assert_equal expected_codelist, codelist
    end
  end

  def test_save_to_default_directory_when_path_not_specified
    Dir.mktmpdir "pirka" do |dir|
      xdh = ENV["XDG_DATA_HOME"]
      begin
        ENV["XDG_DATA_HOME"] = dir
        @library.save
      ensure
        ENV["XDG_DATA_HOME"] = xdh
      end
      path = Pathname.new(dir)/"pirka/local/YWJj.yaml"
      assert_path_exist path

      data = YAML.load_file(path)
      codelist = data.delete("codelist")
      assert_equal @library.metadata, data

      expected_codelist = @library.each.with_object({}) {|(cfi, value), list|
        list[cfi.to_fragment] = value
      }
      assert_equal expected_codelist, codelist
    end
  end

  def test_save_to_specified_directory_when_data_home_is_specified
    Dir.mktmpdir "pirka" do |dir|
      Pirka::Library.data_home = Pathname.new(dir)
      library = Pirka::Library.new
      library.metadata["Release Identifier"] = "abc"
      library.metadata["title"] = "abc"
      library.codelist[EPUB::CFI("/6/30!/4/2/58/2")] = {"language" => "nginx"}
      library.codelist[EPUB::CFI("/6/31!/4/2/56/2")] = {"language" => "nginx"}
      library.codelist[EPUB::CFI("/6/30!/4/2/56/2")] = {"language" => "nginx"}

      library.save

      path = Pathname.new("#{dir}/YWJj.yaml")
      assert_path_exist path.to_path
      assert_equal @yaml, path.read
    end
  end

  def test_save_makes_subdirectory_when_basename_is_longer_than_4_characters
    Dir.mktmpdir "pirka" do |dir|
      Pirka::Library.data_home = Pathname.new(dir)
      library = Pirka::Library.new
      library.metadata["Release Identifier"] = "abcd"

      library.save
      path = Pathname.new(dir)/"YWJj/ZA==.yaml"
      assert_path_exist path
    end
  end

  def test_find_by_release_identifier
    Dir.mktmpdir "pirka" do |dir|
      path = Pathname.new(dir)/"pirka/local/YWJj.yaml"
      path.dirname.mkpath
      path.write(@yaml)
      xdh = ENV["XDG_DATA_HOME"]
      begin
        ENV["XDG_DATA_HOME"] = dir
        library = Pirka::Library.find_by_release_identifier("abc")
      ensure
        ENV["XDG_DATA_HOME"] = xdh
      end
      assert_equal @library.metadata, library.metadata
      assert_equal @library.each.to_a, library.each.to_a
    end
  end
end
