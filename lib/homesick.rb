require 'thor'

class Homesick < Thor
  include Thor::Actions

  GIT_URI_PATTERN = /^git:\/\//
  GITHUB_NAME_REPO_PATTERN = /^[A-Za-z_-]+\/[A-Za-z_-]+$/

  desc "clone URI", "Clone home's +uri+ for use with homesick"
  def clone(uri)
    empty_directory repos_dir
    inside repos_dir do
      if uri =~ GIT_URI_PATTERN
        git_clone uri
      elsif uri =~ GITHUB_NAME_REPO_PATTERN
        match = uri.match(/([A-Za-z_-]+)\/([A-Za-z_-]+)/)
        git_clone "git://github.com/#{match[0]}.git", "#{match[1]}_#{match[2]}"
      end
    end
  end

  desc "link NAME", "Links everything"
  def link(home)
    inside home_dir(home) do
      files = Pathname.glob('.*')[2..-1] # skip . and .., ie the first two
      files.each do |path|
        absolute_path = path.expand_path

        inside user_dir do
          adjusted_path = (user_dir + path).basename
          run "ln -sf #{absolute_path} #{adjusted_path}"
        end
      end
    end
  end

  desc "list", "List installed widgets"
  def list
    inside repos_dir do
      Pathname.glob('*') do |home|
        puts home
      end
    end
  end

  # class method, so it's convenient to stub out during tests
  def self.user_dir
    @user_dir ||= Pathname.new('~').expand_path
  end

  def self.repos_dir
    @repos_dir ||= Pathname.new('~/.homesick/repos').expand_path
  end

  no_tasks do
    def repos_dir
      self.class.repos_dir
    end
  end

  protected

  # TODO move this to be more like thor's template, empty_directory, etc
  def git_clone(repo, destination = nil)
    run "git clone #{repo} #{destination}"
  end

  def user_dir
    self.class.user_dir
  end

  def home_dir(name)
    repos_dir.join(name, 'home')
  end

end
