source 'https://rubygems.org'

group :development, :test do
  unless ENV.key? "CI"
    gem 'epub-parser', path: '../epub-parser'
    gem 'epub-maker', path: '../epub-maker'
  end
end

gemspec

if RUBY_PLATFORM.match /darwin/
  gem 'terminal-notifier'
end
