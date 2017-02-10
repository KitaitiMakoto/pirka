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
  gem.homepage      = "http://www.rubydoc.info/gems/pirka"

  gem.files         = `git ls-files`.split($/)

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

  gem.add_runtime_dependency 'epub-maker'
  gem.add_runtime_dependency 'rouge'
  gem.add_runtime_dependency 'rouge-lexers-fluentd'
  gem.add_runtime_dependency 'optparse-pathname'

  gem.add_development_dependency 'bundler', '~> 1.10'
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'test-unit-notify'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'yard', '~> 0.8'
end
