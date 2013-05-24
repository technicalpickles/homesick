# -*- encoding : utf-8 -*-
require 'thor'

class Homesick < Thor
  autoload :Shell, 'homesick/shell'
  autoload :Actions, 'homesick/actions'

  include Thor::Actions
  include Homesick::Actions

  add_runtime_options!

  GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z_-]+\/[A-Za-z_-]+)\Z/
  SUBDIR_FILENAME = ".homesick_subdir"

  def initialize(args=[], options={}, config={})
    super
    self.shell = Homesick::Shell.new
  end

  desc "clone URI", "Clone +uri+ as a castle for homesick"
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
        destination = Pathname.new($1)
        git_clone "git://github.com/#{$1}.git", :destination => destination
      elsif uri =~ /\/([^\/]*?)(\.git)?\Z/
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

      homesickrc = destination.join('.homesickrc').expand_path
      if homesickrc.exist?
        proceed = shell.yes?("#{uri} has a .homesickrc. Proceed with evaling it? (This could be destructive)")
        if proceed
          shell.say_status "eval", homesickrc
          inside destination do
            eval homesickrc.read, binding, homesickrc.expand_path
          end
        else
          shell.say_status "eval skip", "not evaling #{homesickrc}, #{destination} may need manual configuration", :blue
        end
      end
    end
  end

  desc "pull CASTLE", "Update the specified castle"
  method_option :all, :type => :boolean, :default => false, :required => false, :desc => "Update all cloned castles"
  def pull(name="")
    if options[:all]
      inside_each_castle do |castle|
        shell.say castle.to_s.gsub(repos_dir.to_s + '/', '') + ':'
        update_castle castle
      end
    else
      update_castle name
    end

  end

  desc "commit CASTLE", "Commit the specified castle's changes"
  def commit(name)
    commit_castle name

  end

  desc "push CASTLE", "Push the specified castle"
  def push(name)
    push_castle name

  end

  desc "symlink CASTLE", "Symlinks all dotfiles from the specified castle"
  method_option :force, :default => false, :desc => "Overwrite existing conflicting symlinks without prompting."
  def symlink(name)
    check_castle_existance(name, "symlink")

    inside castle_dir(name) do
      # prepare subdir information
      subdir_file = Pathname.new(".").join(SUBDIR_FILENAME)
      subdirs = []
      if subdir_file.exist? then
        subdir_file.readlines.each do |subdir|
          subdirs.push(subdir.chomp)
        end
      end

      # link files
      files = Pathname.glob('{.*,*}').reject{|a| [".", "..", SUBDIR_FILENAME, subdirs].flatten.include?(a.to_s)}
      files.each do |path|
        absolute_path = path.expand_path

        inside home_dir do
          adjusted_path = (home_dir + path).basename

          ln_s absolute_path, adjusted_path
        end
      end

      # link files in subdirs
      subdirs.each do |subdir|
        inside subdir do
          files = Pathname.glob('{.*,*}').reject{|a| [".", ".."].include?(a.to_s)}
          files.each do |path|
            absolute_path = path.expand_path

            inside home_dir.join(subdir) do
              adjusted_path =  (home_dir + path).basename

              ln_s absolute_path, adjusted_path
            end
          end
        end
      end
    end
  end

  desc "track FILE CASTLE", "add a file to a castle"
  def track(file, castle)
    castle = Pathname.new(castle)
    file = Pathname.new(file.chomp('/'))
    check_castle_existance(castle, 'track')

    absolute_path = file.expand_path
    relative_dir = absolute_path.relative_path_from(home_dir).dirname
    castle_path = Pathname.new(castle_dir(castle)).join(relative_dir)

    unless castle_path.exist?
      FileUtils.mkdir_p castle_path
    end

    # Are we already tracking this or anything inside it?
    target = Pathname.new(castle_path.join(file.basename))

    if target.exist?

      if absolute_path.directory?
        child_files = absolute_path.children
        child_files.each do |child|

          if target.join(child.basename).exist?
            next
          end

          mv child, target
        end
        absolute_path.rmtree
        manifest = Pathname.new(repos_dir.join(castle, '.manifest'))
        if manifest.exist?
          lines = IO.readlines(manifest).delete_if { |line| line == "#{relative_dir + file.basename}\n" }
          File.open(manifest, 'w') { |manfile| manfile.puts lines }
        end

      elsif absolute_path.mtime > target.mtime && !absolute_path.symlink?
        target.delete
        mv absolute_path, castle_path
      else
        shell.say_status(:track, "#{target} already exists, and is more recent than #{file}. Run 'homesick SYMLINK CASTLE' to create symlinks.")
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

    # are we tracking something nested? Add the parent dir to the manifest unless its already listed
    unless relative_dir.eql?(Pathname.new('.'))
      manifest_path = Pathname.new(repos_dir.join(castle, '.manifest'))
      File.open(manifest_path, 'a+') do |manifest|
        manifest.puts relative_dir unless manifest.readlines.inject(false) { |memo, line| line.eql?("#{relative_dir.to_s}\n") || memo }
      end
    end

  end

  desc "list", "List cloned castles"
  def list
    inside_each_castle do |castle|
      say_status castle.relative_path_from(repos_dir).to_s, `git config remote.origin.url`.chomp, :cyan
    end
  end

  desc "generate PATH", "generate a homesick-ready git repo at PATH"
  def generate(castle)
    castle = Pathname.new(castle).expand_path

    github_user = `git config github.user`.chomp
    github_user = nil if github_user == ""
    github_repo = castle.basename

    empty_directory castle
    inside castle do
      git_init
      if github_user
        url = "git@github.com:#{github_user}/#{github_repo}.git"
        git_remote_add 'origin', url
      end

      empty_directory "home"
    end
  end

  desc "destroy CASTLE", "Delete all symlinks and remove the cloned repository"
  def destroy(name)
    check_castle_existance name, "destroy"

    inside castle_dir(name) do
      files = Pathname.glob('{.*,*}').reject{|a| [".",".."].include?(a.to_s)}
      files.each do |path|

        inside home_dir do
          adjusted_path = (home_dir + path).basename
          rm adjusted_path
        end
      end
      rm_rf repos_dir + name
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
      dirs.any? {|other| dir != other && dir.fnmatch(other.parent.join('*').to_s) }
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
    check_castle_existance(castle, "pull")
    inside repos_dir.join(castle) do
      git_pull
      git_submodule_init
      git_submodule_update
    end
  end

  def commit_castle(castle)
    check_castle_existance(castle, "commit")
    inside repos_dir.join(castle) do
      git_commit_all
    end
  end

  def push_castle(castle)
    check_castle_existance(castle, "push")
    inside repos_dir.join(castle) do
      git_push
    end
  end
end
