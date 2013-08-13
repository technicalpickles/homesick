module Homesick
  module Commands
    class Clone < Thor
      include Thor::Actions
      include Homesick::Actions
      include Homesick::Helpers

      add_runtime_options!

      GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z_-]+\/[A-Za-z_-]+)\Z/

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
            destination = Pathname.new($1)
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

      default_task :clone
    end
  end
end
