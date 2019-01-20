require 'homesick/actions/file_actions'
require 'homesick/actions/git_actions'
require 'homesick/version'
require 'homesick/utils'
require 'homesick/cli'
require 'fileutils'

# Homesick's top-level module
module Homesick
  GITHUB_NAME_REPO_PATTERN = %r{\A([A-Za-z0-9_-]+/[A-Za-z0-9_-]+)\Z}.freeze
  SUBDIR_FILENAME = '.homesick_subdir'.freeze

  DEFAULT_CASTLE_NAME = 'dotfiles'.freeze
  QUIETABLE = [:say_status].freeze

  PRETENDABLE = [:system].freeze

  QUIETABLE.each do |method_name|
    define_method(method_name) do |*args|
      super(*args) unless options[:quiet]
    end
  end

  PRETENDABLE.each do |method_name|
    define_method(method_name) do |*args|
      super(*args) unless options[:pretend]
    end
  end
end
