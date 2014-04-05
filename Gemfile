require 'rbconfig'
source 'https://rubygems.org'

# Add dependencies required to use your gem here.
gem "thor", ">= 0.14.0"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rake", ">= 0.8.7"
  gem "rspec", "~> 2.10"
  gem "guard"
  gem "guard-rspec"
  gem "rb-readline", "~> 0.5.0"
  gem "jeweler", ">= 1.6.2"
  gem "simplecov"
  gem "test_construct"
  gem "capture-output", "~> 1.0.0"
  if RbConfig::CONFIG['host_os'] =~ /linux|freebsd|openbsd|sunos|solaris/
    gem 'libnotify'
  end
  if RUBY_VERSION >= '1.9.2'
    gem "rubocop"
  end
end
