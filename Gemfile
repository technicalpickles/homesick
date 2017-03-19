source 'https://rubygems.org'

this_ruby = Gem::Version.new(RUBY_VERSION)
ruby_230 = Gem::Version.new('2.3.0')

# Add dependencies required to use your gem here.
gem 'thor', '>= 0.14.0'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'capture-output', '~> 1.0.0'
  gem 'coveralls', require: false
  gem 'guard'
  gem 'guard-rspec'
  gem 'jeweler', '>= 1.6.2', '< 2.2' if this_ruby < ruby_230
  gem 'jeweler', '>= 1.6.2' if this_ruby >= ruby_230
  gem 'rake', '>= 0.8.7'
  gem 'rb-readline', '~> 0.5.0'
  gem 'rspec', '~> 3.5.0'
  gem 'rubocop'
  gem 'test_construct'

  install_if -> { RUBY_PLATFORM =~ /linux|freebsd|openbsd|sunos|solaris/ } do
    gem 'libnotify'
  end

  install_if -> { RUBY_PLATFORM =~ /darwin/ } do
    gem 'terminal-notifier-guard', '~> 1.7.0'
  end

  install_if -> { this_ruby < ruby_230 } do
    gem 'listen', '< 3'
    gem 'rack', '< 2'
  end
end
