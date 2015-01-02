# -*- encoding : utf-8 -*-
module Homesick
  # A representation of Homesick's version number in constants, including a
  # String of the entire version number
  module Version
    MAJOR = 1
    MINOR = 1
    PATCH = 2

    STRING = [MAJOR, MINOR, PATCH].compact.join('.')
  end
end
