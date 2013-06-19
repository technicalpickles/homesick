require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "homesick"
  gem.summary = %Q{A man's home is his castle. Never leave your dotfiles behind.}
  gem.description = %Q{
    A man's home (directory) is his castle, so don't leave home with out it.

    Homesick is sorta like rip, but for dotfiles. It uses git to clone a repository containing dotfiles, and saves them in ~/.homesick. It then allows you to symlink all the dotfiles into place with a single command. 

  }
  gem.email = ["josh@technicalpickles.com", "info@muratayusuke.com"]
  gem.homepage = "http://github.com/technicalpickles/homesick"
  gem.authors = ["Joshua Nichols", "Yusuke Murata"]
  gem.version = "0.9.1"
  gem.license = "MIT"
  # Have dependencies? Add them to Gemfile

  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
end
Jeweler::GemcutterTasks.new


require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :rubocop do
  if RUBY_VERSION >= '1.9.2'
    raise unless system('rubocop')
  end
end

task :test do
  Rake::Task['spec'].execute
  Rake::Task['rubocop'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "homesick #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

