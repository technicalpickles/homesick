module Homesick
  module Helpers
    SUBDIR_FILENAME = '.homesick_subdir'

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

    def commit_castle(castle)
      check_castle_existance(castle, 'commit')
      inside repos_dir.join(castle) do
        git_commit_all
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
end
