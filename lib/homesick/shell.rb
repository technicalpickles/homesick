class Homesick
  # Hack in support for diffing symlinks
  class Shell < Thor::Shell::Color

    def show_diff(destination, content)
      destination = Pathname.new(destination)

      if destination.symlink?
        say "- #{destination.readlink}", :red, true
        say "+ #{content.expand_path}", :green, true
      else
        super
      end
    end

  end
end
