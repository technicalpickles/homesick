require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :rubocop do
  if RUBY_VERSION >= '1.9.2'
    system('rubocop')
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

