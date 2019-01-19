require 'homesick/actions/file_actions'
require 'homesick/actions/git_actions'
require 'homesick/version'
require 'homesick/utils'
require 'homesick/cli'

# Homesick's top-level module
module Homesick
  GITHUB_NAME_REPO_PATTERN = %r{\A([A-Za-z0-9_-]+/[A-Za-z0-9_-]+)\Z}.freeze
  SUBDIR_FILENAME = '.homesick_subdir'.freeze

  DEFAULT_CASTLE_NAME = 'dotfiles'.freeze
end
