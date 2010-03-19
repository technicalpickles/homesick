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
            system "ln -sf #{source} #{destination}" unless options[:pretend]
          end
        end
      else
        say_status :symlink, "#{source.expand_path} to #{destination.expand_path}", :green
        system "ln -s #{source} #{destination}" unless options[:pretend]
      end
    end
  end
end
