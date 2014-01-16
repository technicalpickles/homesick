# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'homesick'
require './lib/homesick/version'

Gem::Specification.new do |spec|
  spec.name          = "homesick"
  spec.version       = Homesick::Version::STRING
  spec.authors       = ["Joshua Nichols", "Yusuke Murata"]
  spec.email         = ["josh@technicalpickles.com", "info@muratayusuke.com"]
  spec.summary       = "Your home directory is your castle. Don't leave your dotfiles behind."
  spec.description   = %Q{
    Your home directory is your castle. Don't leave your dotfiles behind.
    

    Homesick is sorta like rip, but for dotfiles. It uses git to clone a repository containing dotfiles, and saves them in ~/.homesick. It then allows you to symlink all the dotfiles into place with a single command. 

  }
  spec.homepage      = "http://github.com/technicalpickles/homesick"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = [
    "ChangeLog.md",
    "LICENSE.txt",
    "README.md"
  ]

  # Add dependencies required to use your gem here.
  spec.add_runtime_dependency "thor", ">= 0.14.0"

  # Add dependencies to develop your gem here.
  # Include everything needed to run rake, tests, features, etc.
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "rb-readline", "~> 0.5.0"
  #spec.add_development_dependency "rcov", ">= 0" # TODO: Use this on Ruby 1.8 only
  spec.add_development_dependency "simplecov", ">= 0" # TODO: Use this on Ruby 1.9+ only
  spec.add_development_dependency "test_construct", ">= 0"
  spec.add_development_dependency "capture-output", "~> 1.0.0"
  if RbConfig::CONFIG['host_os'] =~ /linux|freebsd|openbsd|sunos|solaris/
    spec.add_development_dependency 'libnotify'
  end
  if RUBY_VERSION >= '1.9.2'
    spec.add_development_dependency "rubocop"
  end
end
