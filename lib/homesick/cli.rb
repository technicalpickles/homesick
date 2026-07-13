# frozen_string_literal: true

require 'fileutils'
require 'thor'

module Homesick
  # Homesick's command line interface
  class CLI < Thor
    include Thor::Actions
    include Homesick::Actions::FileActions
    include Homesick::Actions::GitActions
    include Homesick::Version
    include Homesick::Utils

    add_runtime_options!

    def self.exit_on_failure?
      true
    end

    map '-v' => :version
    map '--version' => :version
    # Retain a mapped version of the symlink command for compatibility.
    map symlink: :link

    def initialize(args = [], options = {}, config = {})
      super
      # Check if git is installed
      unless git_version_correct?
        say_status :error,
                   "Git version >= #{Homesick::Actions::GitActions::STRING} must be installed to use Homesick",
                   :red
        exit(1)
      end
      configure_symlinks_diff
    end

    desc 'clone URI CASTLE_NAME', 'Clone +uri+ as a castle with name CASTLE_NAME for homesick'
    def clone(uri, destination = nil)
      destination = Pathname.new(destination) unless destination.nil?

      inside repos_dir do
        destination = clone_from_uri(uri, destination)
        setup_castle(destination)
      end
    end

    desc 'rc CASTLE', 'Run the .homesickrc for the specified castle'
    method_option :force,
                  type: :boolean,
                  default: false,
                  desc: 'Evaluate .homesickrc without prompting.'
    def rc(name = DEFAULT_CASTLE_NAME)
      inside repos_dir do
        destination = Pathname.new(name)
        homesickrc = destination.join('.homesickrc').expand_path
        return unless homesickrc.exist?

        proceed = options[:force] ||
                  shell.yes?("#{name} has a .homesickrc. Proceed with evaling it? (This could be destructive)")
        unless proceed
          return say_status 'eval skip',
                            "not evaling #{homesickrc}, #{destination} may need manual configuration",
                            :blue
        end

        say_status 'eval', homesickrc
        inside destination do
          ctx = Homesick::RC::Context.new(destination.expand_path)
          ctx.instance_eval(homesickrc.read, homesickrc.expand_path.to_s)
        end
      end
    end

    desc 'pull CASTLE', 'Update the specified castle'
    method_option :all,
                  type: :boolean,
                  default: false,
                  required: false,
                  desc: 'Update all cloned castles'
    def pull(name = DEFAULT_CASTLE_NAME)
      if options[:all]
        inside_each_castle do |castle|
          say "#{castle.to_s.gsub("#{repos_dir}/", '')}:"
          update_castle castle
        end
      else
        update_castle name
      end
    end

    desc 'commit CASTLE MESSAGE', "Commit the specified castle's changes"
    def commit(name = DEFAULT_CASTLE_NAME, message = nil)
      commit_castle name, message
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

    desc 'link CASTLE', 'Symlinks all dotfiles from the specified castle'
    method_option :force,
                  type: :boolean,
                  default: false,
                  desc: 'Overwrite existing conflicting symlinks without prompting.'
    def link(name = DEFAULT_CASTLE_NAME)
      check_castle_existance(name, 'symlink')

      castle_path = castle_dir(name)
      inside castle_path do
        subdirs = subdirs(name)

        # link files
        symlink_each(name, castle_path, subdirs)

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

      target = Pathname.new(castle_path.join(file.basename))
      if target.exist?
        handle_existing_track_target(castle, absolute_path, castle_path, relative_dir, file, target)
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

      subdir_add(castle, relative_dir) unless relative_dir.eql?(Pathname.new('.'))
    end

    desc 'list', 'List cloned castles'
    def list
      inside_each_castle do |castle|
        say_status castle.relative_path_from(repos_dir).to_s,
                   `git config remote.origin.url`.chomp,
                   :cyan
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

    desc 'destroy CASTLE', 'Delete all symlinks and remove the cloned repository'
    def destroy(name)
      check_castle_existance name, 'destroy'
      return unless shell.yes?('This will destroy your castle irreversible! Are you sure?')

      unlink(name)
      rm_rf repos_dir.join(name)
    end

    desc 'cd CASTLE', 'Open a new shell in the root of the given castle'
    def cd(castle = DEFAULT_CASTLE_NAME)
      check_castle_existance castle, 'cd'
      castle_dir = repos_dir.join(castle)
      say_status "cd #{castle_dir.realpath}",
                 "Opening a new shell in castle '#{castle}'. To return to the original one exit from the new shell.",
                 :green
      inside castle_dir do
        shell = ENV.fetch('SHELL', nil)
        system("HOMESICK_SHELL=1 #{shell}") if shell
      end
    end

    desc 'open CASTLE',
         'Open your default editor in the root of the given castle'
    def open(castle = DEFAULT_CASTLE_NAME)
      unless ENV.fetch('EDITOR', nil)
        say_status :error,
                   'The $EDITOR environment variable must be set to use this command',
                   :red

        exit(1)
      end
      check_castle_existance castle, 'open'
      castle_dir = repos_dir.join(castle)
      say_status "#{castle_dir.realpath}: #{ENV.fetch('EDITOR', nil)} .",
                 "Opening the root directory of castle '#{castle}' in editor '#{ENV.fetch('EDITOR', nil)}'.",
                 :green
      inside castle_dir do
        system("#{ENV.fetch('EDITOR', nil)} .")
      end
    end

    desc 'exec CASTLE COMMAND',
         'Execute a single shell command inside the root of a castle'
    def exec(castle, *args)
      check_castle_existance castle, 'exec'
      unless args.any?
        say_status :error,
                   'You must pass a shell command to execute',
                   :red
        exit(1)
      end
      full_command = args.join(' ')
      action = options[:pretend] ? 'Would execute' : 'Executing command'
      say_status "exec '#{full_command}'",
                 "#{action} '#{full_command}' in castle '#{castle}'",
                 :green
      inside repos_dir.join(castle) do
        system(full_command)
      end
    end

    desc 'exec_all COMMAND',
         'Execute a single shell command inside the root of every cloned castle'
    def exec_all(*args)
      unless args.any?
        say_status :error,
                   'You must pass a shell command to execute',
                   :red
        exit(1)
      end
      full_command = args.join(' ')
      inside_each_castle do |castle|
        action = options[:pretend] ? 'Would execute' : 'Executing command'
        say_status "exec '#{full_command}'",
                   "#{action} '#{full_command}' in castle '#{castle}'",
                   :green
        system(full_command)
      end
    end

    desc 'version', 'Display the current version of homesick'
    def version
      say Homesick::Version::STRING
    end
  end
end
