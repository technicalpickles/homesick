# -*- encoding : utf-8 -*-

# Homesick's top-level module
module Homesick
  autoload :Shell, 'homesick/shell'
  autoload :Actions, 'homesick/actions'
  autoload :Version, 'homesick/version'
  autoload :Utils, 'homesick/utils'
  autoload :CLI, 'homesick/cli'

  GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z0-9_-]+\/[A-Za-z0-9_-]+)\Z/
  SUBDIR_FILENAME = '.homesick_subdir'

  DEFAULT_CASTLE_NAME = 'dotfiles'
end
