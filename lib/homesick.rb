require 'thor'

class Homesick < Thor
  MANIFEST_FILENAME = '.manifest'
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
    castle = castle_dir(name)

    inside castle do
      manifest(castle).each do |line|
        line = line.chomp
        directory = Pathname.new(line)

        home_path = home_dir + line
        mkdir_p home_path.dirname
        ln_s directory.expand_path, home_path
      end

      files = Pathname.glob('**/*', File::FNM_DOTMATCH).select { |path| path.file? }
      files.each do |path|
        next if path_or_parent_listed_in_manifest(path, castle)

        home_path = home_dir + path

        mkdir_p home_path.dirname
        ln_s path.expand_path, home_path
      end
    end
  end

  desc "track PATH CASTLE", "add a PATH to a castle"
  def track(path, castle)
    castle = Pathname.new(castle)
    path = Pathname.new(path.to_s.chomp('/')).expand_path
    check_castle_existance(castle, 'track')

    castle = castle_dir(castle)
    return if path_already_in_castle(path, castle)

    relative_path = path.relative_path_from(home_dir)
    castle_path = castle.join(relative_path)

    merge_path_from_castle path, castle_path, castle if castle_path.exist?

    castle_path.dirname.tap do |parent_dir|
      FileUtils.mkdir_p parent_dir
      mv path, parent_dir
    end

    inside home_dir do
      if should_symlink? relative_path, castle
        ln_s castle_path, path
        add_to_manifest relative_path, castle if path.directory?
      end
    end

    inside castle do
      git_add castle_path
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

  def manifest(castle)
    return @manifest unless @manifest.nil?
    return if castle.nil?

    manifest_path = manifest_path(castle)
    if manifest_path.exist?
      @manifest = manifest_path.each_line
    else
      @manifest = "".each_line
    end
  end

  def manifest_path(castle)
    repos_dir.join(castle, Homesick::MANIFEST_FILENAME)
  end

  def manifest_lists?(path, castle)
    path = path.to_s
    manifest(castle).find do |line|
      return true if line.strip == path
    end
  end

  def remove_from_manifest(path, castle)
    return unless manifest_lists?(path, castle)
    manifest_path = manifest_path(castle)
    file_changed = false

    lines = manifest(castle).map do |line|
      unless line.strip == path.to_s
        return line
      end
      file_changed = true
      nil
    end

    return unless file_changed
    @manifest = nil
    manifest_path.open('w') do |f|
      f.puts lines.compact
    end
  end

  def path_or_parent_listed_in_manifest(path, castle)
    path.descend do |p|
      return true if manifest_lists?(p, castle)
    end
    false
  end

  def add_to_manifest(path, castle)
    return if path_or_parent_listed_in_manifest(path, castle)
    @manifest = nil
    manifest_path(castle).open('a') do |f|
      f.puts path
    end
  end

  def path_already_in_castle(path, castle)
    path = path.realpath.to_s
    castle = castle.realpath.to_s

    path.start_with? castle
  end

  def should_symlink?(path, castle_path)
      should_symlink = true
      path.descend do |p|
        next unless path.exist? && path_already_in_castle(p, castle_path)
        should_symlink = false
        break
      end
      should_symlink
  end

  def merge_path_from_castle(path, castle_path, castle)
    castle_path.children.each do |child|
      file = path + child.basename
      FileUtils.rm file if file.realpath == child
      FileUtils.mv child, path, :force => true
      remove_from_manifest child.relative_path_from(castle), castle
    end
    FileUtils.rmdir castle_path
  end
end
