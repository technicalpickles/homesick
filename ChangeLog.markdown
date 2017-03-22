#1.1.4
 * Make sure symlink conflicts are explicitly communicated to a user and symlinks are not silently overwritten
 * Use real paths of symlinks when linking a castle into home
 * Fix a problem when in a diff when asking a user to resolve a conflict
 * Some code refactoring and fixes

#1.1.3
 * Allow a destination to be passed when cloning a castle
 * Make sure `homesick edit` opens default editor in the root of the given castle
 * Fixed bug when diffing edited files
 * Fixed crashing bug when attempting to diff directories
 * Ensure that messages are escaped correctly on `git commit all`

#1.1.2
 * Added '--force' option to the rc command to bypass confirmation checks when running a .homesickrc file
 * Added a check to make sure that a minimum of Git 1.8.0 is installed. This stops Homesick failing silently if Git is not installed.
 * Code refactoring and fixes.

#1.1.0
 * Added exec and exec_all commands to run commands inside one or all clones castles.
 * Code refactoring.

#1.0.0
 * Removed support for Ruby 1.8.7
 * Added a version command

# 0.9.8
 * Introduce new commands
     * `homesick cd`
     * `homesick open`

# 0.9.4
 * Use https protocol instead of git protocol
 * Introduce new commands
     * `homesick unlink`
     * `homesick rc`

# 0.9.3
 * Add recursive option to `homesick clone`

# 0.9.2
 * Set "dotfiles" as default castle name
 * Introduce new commands
     * `homesick show_path`
     * `homesick status`
     * `homesick diff`

# 0.9.1
 * Fixed small bugs: #35, #40

# 0.9.0
 * Introduce .homesick_subdir #39

# 0.8.1
 * Fixed `homesick list` bug on ruby 2.0 #37

# 0.8.0
 * Introduce commit & push command
 * commit changes in castle and push to remote
 * Enable recursive submodule update
 * Git add when track

# 0.7.0
 * Fixed double-cloning #14
 * New option for pull command: --all
  * pulls each castle, instead of just one

# 0.6.1

 * Add a license

# 0.6.0

 * Introduce .homesickrc
  * Castles can now have a .homesickrc inside them
  * On clone, this is eval'd inside the destination directory
 * Introduce track command
  * Allows easily moving an existing file into a castle, and symlinking it back

# 0.5.0

 * Fixed listing of castles cloned using `homesick clone <github-user>/<github-repo>` (issue 3)
 * Added `homesick pull <CASTLE>` for updating castles (thanks Jorge Dias!)
 * Added a very basic `homesick generate <CASTLE>`

# 0.4.1

 * Improved error message when a castle's home dir doesn't exist

# 0.4.0

 * `homesick clone` can now take a path to a directory on the filesystem, which will be symlinked into place
 * `homesick clone` now tries to `git submodule init` and `git submodule update` if git submodules are defined for a cloned repo
 * Fixed missing dependency on thor and others
 * Use HOME environment variable for where to store files, instead of assuming ~

# 0.3.0

 * Renamed 'link' to 'symlink'
 * Fixed conflict resolution when symlink destination exists and is a normal file

# 0.2.0

 * Better support for recognizing git urls (thanks jacobat!)
	 * if it looks like a github user/repo, do that
	 * otherwise hand off to git clone
 * Listing now displays in color, and show git remote
 * Support pretend, force, and quiet modes

# 0.1.1

 * Fixed trying to link against castles that don't exist
 * Fixed linking, which tries to exclude . and .. from the list of files to
 link (thanks Martinos!)

# 0.1.0

 * Initial release
