module Homesick
  module Commands
    class Pull < Thor
      include Thor::Actions
      include Homesick::Actions
      include Homesick::Helpers

      add_runtime_options!

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

      default_task :pull
    end
  end
end
