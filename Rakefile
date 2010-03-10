require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:runtime, :development)
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
    A man’s home (directory) is his castle, so don’t leave home with out it.

    Homesick is sorta like rip, but for dotfiles. It uses git to clone a repository containing dotfiles, and saves them in ~/.homesick. It then allows you to symlink all the dotfiles into place with a single command. 

  }
  gem.email = "josh@technicalpickles.com"
  gem.homepage = "http://github.com/technicalpickles/homesick"
  gem.authors = ["Joshua Nichols"]
  gem.version = "0.1.0"
  # Have dependencies? Add them to Gemfile

  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
end
Jeweler::GemcutterTasks.new


require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "homesick #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

