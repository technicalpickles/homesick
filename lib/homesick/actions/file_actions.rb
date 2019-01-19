module Homesick
  module Actions
    # File-related helper methods for Homesick
    module FileActions
      protected

      def mv(source, destination)
        source = Pathname.new(source)
        destination = Pathname.new(destination + source.basename)
        say_status :conflict, "#{destination} exists", :red if destination.exist? && (options[:force] || shell.file_collision(destination) { source })
        FileUtils.mv source, destination unless options[:pretend]
      end

      def rm_rf(dir)
        say_status "rm -rf #{dir}", '', :green
        FileUtils.rm_r dir, force: true
      end

      def rm_link(target)
        target = Pathname.new(target)

        if target.symlink?
          say_status :unlink, target.expand_path.to_s, :green
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

        action = :success
        action = :identical if destination.symlink? && destination.readlink == source
        action = :symlink_conflict if destination.symlink?
        action = :conflict if destination.exist?

        handle_symlink_action action, source, destination
      end

      def handle_symlink_action(action, source, destination)
        if action == :identical
          say_status :identical, destination.expand_path, :blue
          return
        end
        message = generate_symlink_message action, source, destination
        if %i[symlink_conflict conflict].include?(action)
          say_status :conflict, message, :red
          if collision_accepted?(destination, source)
            FileUtils.rm_r destination, force: true unless options[:pretend]
          end
        else
          say_status :symlink, message, :green
        end
        FileUtils.ln_s source, destination, force: true unless options[:pretend]
      end

      def generate_symlink_message(action, source, destination)
        message = "#{source.expand_path} to #{destination.expand_path}"
        message = "#{destination} exists and points to #{destination.readlink}" if action == :symlink_conflict
        message = "#{destination} exists" if action == :conflict
        message
      end
    end
  end
end
