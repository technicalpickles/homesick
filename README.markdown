# homesick

A man's home (directory) is his castle, so don't leave home with out it.

Homesick is sorta like [rip](http://github.com/defunkt/rip), but for dotfiles. It uses git to clone a repository containing dotfiles, and saves them in `~/.homesick`. It then allows you to symlink all the dotfiles into place with a single command.

We call a repository that is compatible with homesick to be a 'castle'. To act as a castle, a repository must be organized like so:

* Contains a 'home' directory
* 'home' contains any number of files and directories that begin with '.'

To get started, install homesick first:

    gem install homesick

Next, you use the homesick command to clone a castle:

    homesick clone git://github.com/technicalpickles/pickled-vim.git

Alternatively, if it's on github, there's a slightly shorter way:

    homesick clone technicalpickles/pickled-vim

With the castle cloned, you can now link its contents into your home dir:

    homesick symlink pickled-vim

If you use the shorthand syntax for GitHub repositories in your clone, please note you will instead need to run:

    homesick symlink technicalpickles/pickled-vim

If you're not sure what castles you have around, you can easily list them:

    homesick list

Not sure what else homesick has up its sleeve? There's always the built in help:

    homesick help

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history.  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Need homesick without the ruby dependency?

Check out [homeshick](https://github.com/andsens/homeshick).

## Copyright

Copyright (c) 2010 Joshua Nichols. See LICENSE for details.
