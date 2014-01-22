# -*- encoding : utf-8 -*-
require 'thor'

class Homesick < Thor
  autoload :Shell, 'homesick/shell'
  autoload :Actions, 'homesick/actions'
  autoload :Version, 'homesick/version'

  include Thor::Actions
  include Homesick::Actions
  include Homesick::Version

  add_runtime_options!

  GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z0-9_-]+\/[A-Za-z0-9_-]+)\Z/
  SUBDIR_FILENAME = '.homesick_subdir'

  DEFAULT_CASTLE_NAME = 'dotfiles'

  map '-v' => :version
  map '--version' => :version
  # Retain a mapped version of the symlink command for compatibility.
  map 'symlink' => :link

  def initialize(args = [], options = {}, config = {})
    super
    self.shell = Homesick::Shell.new
  end

  desc 'clone URI', 'Clone +uri+ as a castle for homesick'
  def clone(uri)
    inside repos_dir do
      destination = nil
      if File.exist?(uri)
        uri = Pathname.new(uri).expand_path
        if uri.to_s.start_with?(repos_dir.to_s)
          raise "Castle already cloned to #{uri}"
        end

        destination = uri.basename

        ln_s uri, destination
      elsif uri =~ GITHUB_NAME_REPO_PATTERN
        destination = Pathname.new(uri).basename
        git_clone "https://github.com/#{$1}.git", :destination => destination
      elsif uri =~ /%r([^%r]*?)(\.git)?\Z/
        destination = Pathname.new($1)
        git_clone uri
      elsif uri =~ /[^:]+:([^:]+)(\.git)?\Z/
        destination = Pathname.new($1)
        git_clone uri
      else
        raise "Unknown URI format: #{uri}"
      end

      if destination.join('.gitmodules').exist?
        inside destination do
          git_submodule_init
          git_submodule_update
        end
      end

      rc(destination)
    end
  end

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
  method_option :force, :default => false, :desc => 'Overwrite existing conflicting symlinks without prompting.'
  def link(name = DEFAULT_CASTLE_NAME)
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

  desc "destroy CASTLE", "Delete all symlinks and remove the cloned repository"
  def destroy(name)
    check_castle_existance name, "destroy"

    if shell.yes?("This will destroy your castle irreversible! Are you sure?")
      unlink(name)
      rm_rf repos_dir.join(name)
    end

  end

  desc "cd CASTLE", "Open a new shell in the root of the given castle"
  def cd(castle = DEFAULT_CASTLE_NAME)
    check_castle_existance castle, "cd"
    castle_dir = repos_dir.join(castle)
    say_status "cd #{castle_dir.realpath}", "Opening a new shell in castle '#{castle}'. To return to the original one exit from the new shell.", :green
    inside castle_dir do
      system(ENV['SHELL'])
    end
  end

  desc "open CASTLE", "Open your default editor in the root of the given castle"
  def open(castle = DEFAULT_CASTLE_NAME)
    if ! ENV['EDITOR']
      say_status :error,"The $EDITOR environment variable must be set to use this command", :red

      exit(1)
    end
    check_castle_existance castle, "open"
    castle_dir = repos_dir.join(castle)
    say_status "#{ENV['EDITOR']} #{castle_dir.realpath}", "Opening the root directory of castle '#{castle}' in editor '#{ENV['EDITOR']}'.", :green
    inside castle_dir do
      system(ENV['EDITOR'])
    end
  end

  desc 'version', 'Display the current version of homesick'
  def version
    say Homesick::Version::STRING
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

  def check_castle_existance(name, action)
    unless castle_dir(name).exist?
      say_status :error, "Could not #{action} #{name}, expected #{castle_dir(name)} exist and contain dotfiles", :red

      exit(1)
    end
  end

  def all_castles
    dirs = Pathname.glob("#{repos_dir}/**/.git", File::FNM_DOTMATCH)
    # reject paths that lie inside another castle, like git submodules
    return dirs.reject do |dir|
      dirs.any? do |other|
        dir != other && dir.fnmatch(other.parent.join('*').to_s)
      end
    end
  end

  def inside_each_castle(&block)
    all_castles.each do |git_dir|
      castle = git_dir.dirname
      Dir.chdir castle do # so we can call git config from the right contxt
        yield castle
      end
    end
  end

  def update_castle(castle)
    check_castle_existance(castle, 'pull')
    inside repos_dir.join(castle) do
      git_pull
      git_submodule_init
      git_submodule_update
    end
  end

  def commit_castle(castle, message)
    check_castle_existance(castle, 'commit')
    inside repos_dir.join(castle) do
      git_commit_all :message => message
    end
  end

  def push_castle(castle)
    check_castle_existance(castle, 'push')
    inside repos_dir.join(castle) do
      git_push
    end
  end

  def subdir_file(castle)
    repos_dir.join(castle, SUBDIR_FILENAME)
  end

  def subdirs(castle)
    subdir_filepath = subdir_file(castle)
    subdirs = []
    if subdir_filepath.exist?
      subdir_filepath.readlines.each do |subdir|
        subdirs.push(subdir.chomp)
      end
    end
    subdirs
  end

  def subdir_add(castle, path)
    subdir_filepath = subdir_file(castle)
    File.open(subdir_filepath, 'a+') do |subdir|
      subdir.puts path unless subdir.readlines.reduce(false) do |memo, line|
        line.eql?("#{path.to_s}\n") || memo
      end
    end

    inside castle_dir(castle) do
      git_add subdir_filepath
    end
  end

  def subdir_remove(castle, path)
    subdir_filepath = subdir_file(castle)
    if subdir_filepath.exist?
      lines = IO.readlines(subdir_filepath).delete_if { |line| line == "#{path}\n" }
      File.open(subdir_filepath, 'w') { |manfile| manfile.puts lines }
    end

    inside castle_dir(castle) do
      git_add subdir_filepath
    end
  end

  def move_dir_contents(target, dir_path)
    child_files = dir_path.children
    child_files.each do |child|

      target_path = target.join(child.basename)
      if target_path.exist?
        if more_recent?(child, target_path) && target.file?
          target_path.delete
          mv child, target
        end
        next
      end

      mv child, target
    end
  end

  def more_recent?(first, second)
    first_p = Pathname.new(first)
    second_p = Pathname.new(second)
    first_p.mtime > second_p.mtime && !first_p.symlink?
  end

  def each_file(castle, basedir, subdirs)
    absolute_basedir = Pathname.new(basedir).expand_path
    inside basedir do
      files = Pathname.glob('{.*,*}').reject{ |a| ['.', '..'].include?(a.to_s) }
      files.each do |path|
        absolute_path = path.expand_path
        castle_home = castle_dir(castle)

        # make ignore dirs
        ignore_dirs = []
        subdirs.each do |subdir|
          # ignore all parent of each line in subdir file
          Pathname.new(subdir).ascend do |p|
            ignore_dirs.push(p)
          end
        end

        # ignore dirs written in subdir file
        matched = false
        ignore_dirs.uniq.each do |ignore_dir|
          if absolute_path == castle_home.join(ignore_dir)
            matched = true
            break
          end
        end
        next if matched

        relative_dir = absolute_basedir.relative_path_from(castle_home)
        home_path = home_dir.join(relative_dir).join(path)

        yield(absolute_path, home_path)
     end
    end
  end

  def unsymlink_each(castle, basedir, subdirs)
    each_file(castle, basedir, subdirs) do |absolute_path, home_path|
      rm_link home_path
    end
  end

  def symlink_each(castle, basedir, subdirs)
    each_file(castle, basedir, subdirs) do |absolute_path, home_path|
      ln_s absolute_path, home_path
    end
  end
end
