module Homesick
  module Actions
    # Git-related helper methods for Homesick
    module GitActions
      # Information on the minimum git version required for Homesick
      MIN_VERSION = {
        major: 1,
        minor: 8,
        patch: 0
      }.freeze
      STRING = MIN_VERSION.values.join('.')

      def git_version_correct?
        info = `git --version`.scan(/(\d+)\.(\d+)\.(\d+)/).flatten.map(&:to_i)
        return false unless info.count == 3

        current_version = Hash[%i[major minor patch].zip(info)]
        major_equals = current_version.eql?(MIN_VERSION)
        major_greater = current_version[:major] > MIN_VERSION[:major]
        minor_greater = current_version[:major] == MIN_VERSION[:major] && current_version[:minor] > MIN_VERSION[:minor]
        patch_greater = current_version[:major] == MIN_VERSION[:major] && current_version[:minor] == MIN_VERSION[:minor] && current_version[:patch] >= MIN_VERSION[:patch]

        major_equals || major_greater || minor_greater || patch_greater
      end

      # TODO: move this to be more like thor's template, empty_directory, etc
      def git_clone(repo, config = {})
        config ||= {}
        destination = config[:destination] || File.basename(repo, '.git')

        destination = Pathname.new(destination) unless destination.is_a?(Pathname)
        FileUtils.mkdir_p destination.dirname

        if destination.directory?
          say_status :exist, destination.expand_path, :blue
        else
          say_status 'git clone',
                     "#{repo} to #{destination.expand_path}",
                     :green
          system "git clone -q --config push.default=upstream --recursive #{repo} #{destination}"
        end
      end

      def git_init(path = '.')
        path = Pathname.new(path)

        inside path do
          if path.join('.git').exist?
            say_status 'git init', 'already initialized', :blue
          else
            say_status 'git init', ''
            system 'git init >/dev/null'
          end
        end
      end

      def git_remote_add(name, url)
        existing_remote = `git config remote.#{name}.url`.chomp
        existing_remote = nil if existing_remote == ''

        if existing_remote
          say_status 'git remote', "#{name} already exists", :blue
        else
          say_status 'git remote', "add #{name} #{url}"
          system "git remote add #{name} #{url}"
        end
      end

      def git_submodule_init
        say_status 'git submodule', 'init', :green
        system 'git submodule --quiet init'
      end

      def git_submodule_update
        say_status 'git submodule', 'update', :green
        system 'git submodule --quiet update --init --recursive >/dev/null 2>&1'
      end

      def git_pull
        say_status 'git pull', '', :green
        system 'git pull --quiet'
      end

      def git_push
        say_status 'git push', '', :green
        system 'git push'
      end

      def git_commit_all(config = {})
        say_status 'git commit all', '', :green
        if config[:message]
          system %(git commit -a -m "#{config[:message]}")
        else
          system 'git commit -v -a'
        end
      end

      def git_add(file)
        say_status 'git add file', '', :green
        system "git add '#{file}'"
      end

      def git_status
        say_status 'git status', '', :green
        system 'git status'
      end

      def git_diff
        say_status 'git diff', '', :green
        system 'git diff'
      end
    end
  end
end
