# -*- encoding : utf-8 -*-
module Homesick
  module Actions
    # File-related helper methods for Homesick
    module FileActions
      def mv(source, destination)
        source = Pathname.new(source)
        destination = Pathname.new(destination + source.basename)
        case
        when destination.exist? && (options[:force] || shell.file_collision(destination) { source })
          say_status :conflict, "#{destination} exists", :red
          FileUtils.mv source, destination unless options[:pretend]
        else
          FileUtils.mv source, destination unless options[:pretend]
        end
      end

      def rm_rf(dir)
        say_status "rm -rf #{dir}", '', :green
        FileUtils.rm_r dir, force: true
      end

      def rm_link(target)
        target = Pathname.new(target)

        if target.symlink?
          say_status :unlink, "#{target.expand_path}", :green
          FileUtils.rm_rf target
        else
          say_status :conflict, "#{target} is not a symlink", :red
        end
      end

      def rm(file)
        say_status "rm #{file}", '', :green
        FileUtils.rm file, force: true
      end

      def rm_r(dir)
        say_status "rm -r #{dir}", '', :green
        FileUtils.rm_r dir
      end

      def ln_s(source, destination)
        source = Pathname.new(source).realpath        
        destination = Pathname.new(destination)
        FileUtils.mkdir_p destination.dirname

        action = if destination.symlink? && destination.readlink == source
                   :identical
                 elsif destination.symlink?
                   :symlink_conflict
                 elsif destination.exist?
                   :conflict
                 else
                   :success
                 end

        handle_symlink_action action, source, destination
      end

      def handle_symlink_action(action, source, destination)
        case action
        when :identical
          say_status :identical, destination.expand_path, :blue
        when :symlink_conflict, :conflict
          if action == :conflict
            say_status :conflict, "#{destination} exists", :red
          else
            say_status :conflict,
                      "#{destination} exists and points to #{destination.readlink}",
                      :red
          end
          if collision_accepted?(destination, source)
            FileUtils.rm_r destination, force: true unless options[:pretend]
            FileUtils.ln_s source, destination, force: true unless options[:pretend]
          end
        else
          say_status :symlink,
                     "#{source.expand_path} to #{destination.expand_path}",
                     :green
          FileUtils.ln_s source, destination unless options[:pretend]
        end
      end
    end
  end
end
