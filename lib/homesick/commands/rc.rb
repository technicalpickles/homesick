module Homesick
  module Commands
    class Rc < Thor
      include Thor::Actions
      include Homesick::Actions
      include Homesick::Helpers

      add_runtime_options!

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

      default_task :rc
    end
  end
end
