require 'thor'

class Homesick < Thor
  include Thor::Actions

  desc "clone URI", "Clone home's +uri+ for use with homesick"
  def clone(uri)
    empty_directory homes_dir
    inside homes_dir do
      run "git clone #{uri}"
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
    inside homes_dir do
      Pathname.glob('*') do |home|
        puts home
      end
    end
  end

  protected

  def user_dir
    @user_dir ||= Pathname.new('~').expand_path
  end

  def homes_dir
    @homes_dir ||= Pathname.new('~/.homesick/repos').expand_path
  end

  def home_dir(name)
    homes_dir.join(name, 'home')
  end

end
