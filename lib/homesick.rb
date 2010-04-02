require 'thor'

class Homesick < Thor
  autoload :Shell, 'homesick/shell'
  autoload :Actions, 'homesick/actions'

  include Thor::Actions
  include Homesick::Actions

  add_runtime_options!

  GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z_-]+\/[A-Za-z_-]+)\Z/

  def initialize(args=[], options={}, config={})
    super
    self.shell = Homesick::Shell.new
  end

  desc "clone URI", "Clone +uri+ as a castle for homesick"
  def clone(uri)
    inside repos_dir do
      destination = nil
      if File.exist?(uri)
        destination = Pathname.new(uri).basename

        ln_s uri, destination
      elsif uri =~ GITHUB_NAME_REPO_PATTERN
        destination = Pathname.new($1)
        git_clone "git://github.com/#{$1}.git", :destination => destination
      else
        if uri =~ /\/([^\/]*).git\Z/
          destination = Pathname.new($1)
        end

        git_clone uri
      end

      if destination.join('.gitmodules').exist?
        inside destination do
          git_submodule_init
          git_submodule_update
        end
      end
    end
  end

  desc "symlink NAME", "Symlinks all dotfiles from the specified castle"
  def symlink(home)
    unless castle_dir(home).exist?
      say_status :error, "Castle #{home} did not exist in #{repos_dir}", :red

      exit(1)

    else
      inside castle_dir(home) do
        files = Pathname.glob('.*').reject{|a| [".",".."].include?(a.to_s)}
        files.each do |path|
          absolute_path = path.expand_path

          inside home_dir do
            adjusted_path = (home_dir + path).basename

            ln_s absolute_path, adjusted_path
          end
        end
      end
    end

  end

  desc "list", "List cloned castles"
  def list
    Pathname.glob(repos_dir + "*") do |castle|
      Dir.chdir castle do # so we can call git config from the right contxt
        say_status castle.basename.to_s, `git config remote.origin.url`.chomp, :cyan
      end
    end
  end

  protected

  def home_dir
    @home_dir ||= Pathname.new(ENV['HOME'] || '~').expand_path
  end

  def repos_dir
    @repos_dir ||= home_dir.join('.homesick', 'repos').expand_path
  end


  def castle_dir(name)
    repos_dir.join(name, 'home')
  end

end
