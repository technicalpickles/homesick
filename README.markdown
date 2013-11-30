# homesick

[![Build Status](https://travis-ci.org/technicalpickles/homesick.png?branch=master)](https://travis-ci.org/technicalpickles/homesick)

A person's home (directory) is their castle, so don't leave home with out it.

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


You can remove symlinks anytime when you don't need them anymore

    homesick unlink pickled-vim

If you're not sure what castles you have around, you can easily list them:

    homesick list

To pull your castle (or all castles):

    homesick pull --all|CASTLE

To commit your castle's changes:

    homesick commit CASTLE

To push your castle:

    homesick push CASTLE

Not sure what else homesick has up its sleeve? There's always the built in help:

    homesick help

## .homesick_subdir

`homesick symlink` basically makes symlink to only first depth in `castle/home`. If you want to link nested files/directories, please use .homesick_subdir.

For example, when you have castle like this:

    castle/home
    `-- .config
        `-- fooapp
            |-- config1
            |-- config2
            `-- config3

and have home like this:

    $ tree -a
    ~
    |-- .config
    |   `-- barapp
    |         |-- config1
    |         |-- config2
    |         `-- config3
    `-- .emacs.d
        |-- elisp
        `-- inits

You may want to symlink only to `castle/home/.config/fooapp` instead of `castle/home/.config` because you already have `~/.config/barapp`. In this case, you can use .homesick_subdir. Please write "directories you want to look up sub directories (instead of just first depth)" in this file.

castle/.homesick_subdir

    .config

and run `homesick symlink CASTLE`. The result is:

    ~
    |-- .config
    |   |-- barapp
    |   |     |-- config1
    |   |     |-- config2
    |   |     `-- config3
    |   `-- fooapp        -> castle/home/.config/fooapp
    `-- .emacs.d
        |-- elisp
        `-- inits

Or `homesick track NESTED_FILE CASTLE` adds a line automatically. For example:

    homesick track .emacs.d/elisp castle

castle/.homesick_subdir

    .config
	.emacs.d

home directory

    ~
    |-- .config
    |   |-- barapp
    |   |     |-- config1
    |   |     |-- config2
    |   |     `-- config3
    |   `-- fooapp        -> castle/home/.config/fooapp
    `-- .emacs.d
        |-- elisp         -> castle/home/.emacs.d/elisp
        `-- inits

and castle

    castle/home
    |-- .config
    |   `-- fooapp
    |       |-- config1
    |       |-- config2
    |      `-- config3
    `-- .emacs.d
        `-- elisp

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
