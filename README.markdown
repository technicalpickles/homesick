# homesick

[![Gem Version](https://badge.fury.io/rb/homesick.svg)](http://badge.fury.io/rb/homesick)
[![CI](https://github.com/technicalpickles/homesick/actions/workflows/ci.yml/badge.svg)](https://github.com/technicalpickles/homesick/actions/workflows/ci.yml)

Your home directory is your castle. Don't leave your dotfiles behind.

Homesick is sorta like [rip](http://github.com/defunkt/rip), but for dotfiles. It uses git to clone a repository containing dotfiles, and saves them in `~/.homesick`. It then allows you to symlink all the dotfiles into place with a single command. (Set the `HOMESICKDIR` environment variable if you'd like to use a different location instead of `~/.homesick`.)

We call a repository that is compatible with homesick to be a 'castle'. To act as a castle, a repository must be organized like so:

* Contains a 'home' directory
* 'home' contains any number of files and directories that begin with '.'

To get started, install homesick first:

    gem install homesick

If you're starting from scratch and don't have a castle yet, generate one:

    homesick generate ~/.homesick/repos/my-dotfiles

This creates a new git repository with a `home/` directory ready for your dotfiles. If you have a `github.user` set in your git config, it will also add a GitHub remote automatically. You can then track files into it:

    homesick track ~/.vimrc my-dotfiles

Otherwise, if you already have a castle hosted somewhere, clone it:

Next, you use the homesick command to clone a castle:

    homesick clone git://github.com/technicalpickles/pickled-vim.git

Alternatively, if it's on github, there's a slightly shorter way:

    homesick clone technicalpickles/pickled-vim

With the castle cloned, you can now link its contents into your home dir:

    homesick link pickled-vim

You can remove symlinks anytime when you don't need them anymore

    homesick unlink pickled-vim

If you need to add further configuration steps you can add these in a file called '.homesickrc' in the root of a castle. Once you've cloned a castle with a .homesickrc run the configuration with:

    homesick rc CASTLE

The contents of the .homesickrc file must be valid Ruby code as the file will be executed with Ruby's eval construct. The .homesickrc is also passed the current homesick object during its execution and this is available within the .homesickrc file as the 'self' variable. As the rc operation can be destructive the command normally asks for confirmation before proceeding. You can bypass this by passing the '--force' option, for example `homesick rc --force CASTLE`.

If you're not sure what castles you have around, you can easily list them:

    homesick list

To pull your castle (or all castles):

    homesick pull --all|CASTLE

To commit your castle's changes:

    homesick commit CASTLE

To push your castle:

    homesick push CASTLE

To open a terminal in the root of a castle:

    homesick cd CASTLE

To open your default editor in the root of a castle (the $EDITOR environment variable must be set):

    homesick open CASTLE

To execute a shell command inside the root directory of a given castle:

    homesick exec CASTLE COMMAND

To execute a shell command inside the root directory of every cloned castle:

    homesick exec_all COMMAND

Not sure what else homesick has up its sleeve? There's always the built in help:

    homesick help

If you ever want to see what version of homesick you have type:

    homesick version|-v|--version

## .homesick_subdir

`homesick link` basically makes symlink to only first depth in `castle/home`. If you want to link nested files/directories, please use .homesick_subdir.

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

and run `homesick link CASTLE`. The result is:

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

## Supported Ruby Versions

Homesick is tested on the following Ruby versions:

* 3.2
* 3.3
* 3.4

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so it doesn't get broken unintentionally in a future version.
* Commit, but do not touch the rakefile, version, or history. (If you want your own version, that is fine — just bump the version in a separate commit that can be ignored when merging.)
* Open a pull request. Bonus points for topic branches.

## Need homesick without the ruby dependency?

Check out [homeshick](https://github.com/andsens/homeshick).

## Copyright

Copyright (c) 2010 Joshua Nichols. See LICENSE for details.
