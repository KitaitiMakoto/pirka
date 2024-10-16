# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pirka/version'

Gem::Specification.new do |gem|
  gem.name          = "pirka"
  gem.version       = Pirka::VERSION
  gem.summary       = %q{Syntax highlighting tool for EPUB books}
  gem.description   = %q{Pirka highlights source code syntax in EPUB books}
  gem.license       = "GPL"
  gem.authors       = ["KITAITI Makoto"]
  gem.email         = "KitaitiMakoto@gmail.com"
  gem.homepage      = "https://gitlab.com/KitaitiMakoto/pirka"

  gem.files         = `git ls-files`.split($/)
  gem.files         += Dir.glob("{po,locale}/**/*")

  `git submodule --quiet foreach --recursive pwd`.split($/).each do |submodule|
    submodule.sub!("#{Dir.pwd}/",'')

    Dir.chdir(submodule) do
      `git ls-files`.split($/).map do |subpath|
        gem.files << File.join(submodule,subpath)
      end
    end
  end
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'base64'
  gem.add_runtime_dependency 'epub-parser', ">= #{Pirka::EPUB_PARSER_VERSION}"
  gem.add_runtime_dependency 'epub-maker'
  gem.add_runtime_dependency 'rouge'
  gem.add_runtime_dependency 'rouge-lexers-fluentd'
  gem.add_runtime_dependency 'optparse-pathname'
  gem.add_runtime_dependency 'colored'
  gem.add_runtime_dependency 'gettext'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'test-unit-notify'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'rubygems-tasks'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-doc'
  gem.add_development_dependency 'asciidoctor'
  gem.add_development_dependency 'nokogiri', '< 1.16.0' if RbConfig::CONFIG["MAJOR"] == "2"
end
