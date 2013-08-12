require 'homesick/commands/clone'

module Homesick
  class CLI < Thor
    include Thor::Actions
    include Homesick::Actions
    include Homesick::Helpers

    add_runtime_options!

    DEFAULT_CASTLE_NAME = 'dotfiles'

    def initialize(args = [], options = {}, config = {})
      super
      self.shell = Homesick::Shell.new
    end

    register Homesick::Commands::Clone, "clone", "clone URI", "Clone +uri+ as a castle for homesick"

    desc 'rc CASTLE', 'Run the .homesickrc for the specified castle'
    def rc(name = DEFAULT_CASTLE_NAME)
      inside repos_dir do
        destination = Pathname.new(name)
        homesickrc = destination.join('.homesickrc').expand_path
        if homesickrc.exist?
          proceed = shell.yes?("#{name} has a .homesickrc. Proceed with evaling it? (This could be destructive)")
          if proceed
            shell.say_status 'eval', homesickrc
            inside destination do
              eval homesickrc.read, binding, homesickrc.expand_path.to_s
            end
          else
            shell.say_status 'eval skip', "not evaling #{homesickrc}, #{destination} may need manual configuration", :blue
          end
        end
      end
    end

    desc 'pull CASTLE', 'Update the specified castle'
    method_option :all, :type => :boolean, :default => false, :required => false, :desc => 'Update all cloned castles'
    def pull(name = DEFAULT_CASTLE_NAME)
      if options[:all]
        inside_each_castle do |castle|
          shell.say castle.to_s.gsub(repos_dir.to_s + '/', '') + ':'
          update_castle castle
        end
      else
        update_castle name
      end

    end

    desc 'commit CASTLE', "Commit the specified castle's changes"
    def commit(name = DEFAULT_CASTLE_NAME)
      commit_castle name

    end

    desc 'push CASTLE', 'Push the specified castle'
    def push(name = DEFAULT_CASTLE_NAME)
      push_castle name
    end

    desc 'unlink CASTLE', 'Unsymlinks all dotfiles from the specified castle'
    def unlink(name = DEFAULT_CASTLE_NAME)
      check_castle_existance(name, 'symlink')

      inside castle_dir(name) do
        subdirs = subdirs(name)

        # unlink files
        unsymlink_each(name, castle_dir(name), subdirs)

        # unlink files in subdirs
        subdirs.each do |subdir|
          unsymlink_each(name, subdir, subdirs)
        end
      end
    end

    desc 'symlink CASTLE', 'Symlinks all dotfiles from the specified castle'
    method_option :force, :default => false, :desc => 'Overwrite existing conflicting symlinks without prompting.'
    def symlink(name = DEFAULT_CASTLE_NAME)
      check_castle_existance(name, 'symlink')

      inside castle_dir(name) do
        subdirs = subdirs(name)

        # link files
        symlink_each(name, castle_dir(name), subdirs)

        # link files in subdirs
        subdirs.each do |subdir|
          symlink_each(name, subdir, subdirs)
        end
      end
    end

    desc 'track FILE CASTLE', 'add a file to a castle'
    def track(file, castle = DEFAULT_CASTLE_NAME)
      castle = Pathname.new(castle)
      file = Pathname.new(file.chomp('/'))
      check_castle_existance(castle, 'track')

      absolute_path = file.expand_path
      relative_dir = absolute_path.relative_path_from(home_dir).dirname
      castle_path = Pathname.new(castle_dir(castle)).join(relative_dir)
      FileUtils.mkdir_p castle_path

      # Are we already tracking this or anything inside it?
      target = Pathname.new(castle_path.join(file.basename))
      if target.exist?
        if absolute_path.directory?
          move_dir_contents(target, absolute_path)
          absolute_path.rmtree
          subdir_remove(castle, relative_dir + file.basename)

        elsif more_recent? absolute_path, target
          target.delete
          mv absolute_path, castle_path
        else
          shell.say_status(:track, "#{target} already exists, and is more recent than #{file}. Run 'homesick SYMLINK CASTLE' to create symlinks.", :blue) unless options[:quiet]
        end
      else
        mv absolute_path, castle_path
      end

      inside home_dir do
        absolute_path = castle_path + file.basename
        home_path = home_dir + relative_dir + file.basename
        ln_s absolute_path, home_path
      end

      inside castle_path do
        git_add absolute_path
      end

      # are we tracking something nested? Add the parent dir to the manifest
      subdir_add(castle, relative_dir) unless relative_dir.eql?(Pathname.new('.'))
    end

    desc 'list', 'List cloned castles'
    def list
      inside_each_castle do |castle|
        say_status castle.relative_path_from(repos_dir).to_s, `git config remote.origin.url`.chomp, :cyan
      end
    end

    desc 'status CASTLE', 'Shows the git status of a castle'
    def status(castle = DEFAULT_CASTLE_NAME)
      check_castle_existance(castle, 'status')
      inside repos_dir.join(castle) do
        git_status
      end
    end

    desc 'diff CASTLE', 'Shows the git diff of uncommitted changes in a castle'
    def diff(castle = DEFAULT_CASTLE_NAME)
      check_castle_existance(castle, 'diff')
      inside repos_dir.join(castle) do
        git_diff
      end
    end

    desc 'show_path CASTLE', 'Prints the path of a castle'
    def show_path(castle = DEFAULT_CASTLE_NAME)
      check_castle_existance(castle, 'show_path')
      say repos_dir.join(castle)
    end

    desc 'generate PATH', 'generate a homesick-ready git repo at PATH'
    def generate(castle)
      castle = Pathname.new(castle).expand_path

      github_user = `git config github.user`.chomp
      github_user = nil if github_user == ''
      github_repo = castle.basename

      empty_directory castle
      inside castle do
        git_init
        if github_user
          url = "git@github.com:#{github_user}/#{github_repo}.git"
          git_remote_add 'origin', url
        end

        empty_directory 'home'
      end
    end


  end
end
