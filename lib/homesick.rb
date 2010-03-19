require 'thor'

class Homesick < Thor
  include Thor::Actions

  # Hack in support for diffing symlinks
  class Shell < Thor::Shell::Color

    def show_diff(destination, content)
      destination = Pathname.new(destination)

      if destination.symlink?
        say "- #{destination.readlink}", :red, true
        say "+ #{content.expand_path}", :green, true
      else
        super
      end
    end

  end

  def initialize(args=[], options={}, config={})
    super
    self.shell = Homesick::Shell.new
  end

  GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z_-]+)\/([A-Za-z_-]+)\Z/

  desc "clone URI", "Clone +uri+ as a castle for homesick"
  def clone(uri)
    empty_directory repos_dir, :verbose => false
    inside repos_dir do
      if uri =~ GITHUB_NAME_REPO_PATTERN
        git_clone "git://github.com/#{$1}/#{$2}.git", "#{$1}_#{$2}"
      else
        git_clone uri
      end
    end
  end

  desc "link NAME", "Symlinks all dotfiles from the specified castle"
  def link(home)
    unless castle_dir(home).exist?
      say_status :error, "Castle #{home} did not exist in #{repos_dir}", :red

      exit(1)

    else
      inside castle_dir(home) do
        files = Pathname.glob('.*').reject{|a| [".",".."].include?(a.to_s)}
        files.each do |path|
          absolute_path = path.expand_path

          inside user_dir do
            adjusted_path = (user_dir + path).basename

            symlink absolute_path, adjusted_path
          end
        end
      end
    end

  end

  desc "list", "List cloned castles"
  def list
    inside repos_dir do
      Pathname.glob('*') do |home|
        inside home do
          say_status home, `git config remote.origin.url`
        end
      end
    end
  end


  no_tasks do
    # class method, so it's convenient to stub out during tests
    def self.user_dir
      @user_dir ||= Pathname.new('~').expand_path
    end

    def self.repos_dir
      @repos_dir ||= Pathname.new('~/.homesick/repos').expand_path
    end

    def repos_dir
      self.class.repos_dir
    end
  end

  protected

  # TODO move this to be more like thor's template, empty_directory, etc
  def git_clone(repo, config = {})
    config ||= {}
    destination = config[:destination] || begin
                                            repo =~ /([^\/]+)\.git$/
                                            $1
                                          end

    destination = Pathname.new(destination) unless destination.kind_of?(Pathname)

    if ! destination.directory?
      say_status 'git clone', "#{repo} to #{destination.expand_path}", :green if config.fetch(:verbose, true)
      system "git clone #{repo} #{destination}" unless options[:pretend]
    else
      say_status :exist, destination.expand_path, :blue
    end
  end

  def symlink(source, destination, config = {})
    destination = Pathname.new(destination)

    if destination.symlink?
      if destination.readlink == source
        say_status :identical, destination.expand_path, :blue
      else
        say_status :conflict, "#{destination} exists and points to #{destination.readlink}", :red

        if shell.file_collision(destination) { source }
          system "ln -sf #{source} #{destination}"
        end
      end
    else
      say_status :symlink, "#{source.expand_path} to #{destination.expand_path}", :green
      system "ln -s #{source} #{destination}"
    end
  end

  def user_dir
    self.class.user_dir
  end

  def castle_dir(name)
    repos_dir.join(name, 'home')
  end

end
