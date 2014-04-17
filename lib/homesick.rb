# -*- encoding : utf-8 -*-
require 'homesick/shell'
require 'homesick/actions/file_actions'
require 'homesick/actions/git_actions'
require 'homesick/version'
require 'homesick/utils'
require 'homesick/cli'

# Homesick's top-level module
module Homesick
  GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z0-9_-]+\/[A-Za-z0-9_-]+)\Z/
  SUBDIR_FILENAME = '.homesick_subdir'

  DEFAULT_CASTLE_NAME = 'dotfiles'
end
