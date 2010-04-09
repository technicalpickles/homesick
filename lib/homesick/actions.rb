class Homesick
  module Actions
    # TODO move this to be more like thor's template, empty_directory, etc
    def git_clone(repo, config = {})
      config ||= {}
      destination = config[:destination] || begin
        repo =~ /([^\/]+)\.git$/
       $1
      end

      destination = Pathname.new(destination) unless destination.kind_of?(Pathname)
      FileUtils.mkdir_p destination.dirname

      if ! destination.directory?
        say_status 'git clone', "#{repo} to #{destination.expand_path}", :green unless options[:quiet]
        system "git clone -q #{repo} #{destination}" unless options[:pretend]
      else
        say_status :exist, destination.expand_path, :blue unless options[:quiet]
      end
    end

    def git_submodule_init(config = {})
      say_status 'git submodule', 'init', :green unless options[:quiet]
      system "git submodule --quiet init" unless options[:pretend]
    end

    def git_submodule_update(config = {})
      say_status 'git submodule', 'update', :green unless options[:quiet]
      system "git submodule --quiet update >/dev/null 2>&1" unless options[:pretend]
    end

    def git_pull(config = {})
      say_status 'git pull', '', :green unless options[:quiet]
      system "git pull --quiet" unless options[:pretend]
    end

    def ln_s(source, destination, config = {})
      source = Pathname.new(source)
      destination = Pathname.new(destination)

      if destination.symlink?
        if destination.readlink == source
          say_status :identical, destination.expand_path, :blue unless options[:quiet]
        else
          say_status :conflict, "#{destination} exists and points to #{destination.readlink}", :red unless options[:quiet]

          if shell.file_collision(destination) { source }
            system "ln -sf #{source} #{destination}" unless options[:pretend]
          end
        end
      elsif destination.exist?
        say_status :conflict, "#{destination} exists", :red unless options[:quiet]

        if shell.file_collision(destination) { source }
          system "ln -sf #{source} #{destination}" unless options[:pretend]
        end
      else
        say_status :symlink, "#{source.expand_path} to #{destination.expand_path}", :green unless options[:quiet]
        system "ln -s #{source} #{destination}" unless options[:pretend]
      end
    end
  end
end
