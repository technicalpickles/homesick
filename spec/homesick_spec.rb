require 'spec_helper'

describe Homesick do
  before do
    @homesick = Homesick.new
  end

  describe "clone" do
    it "should clone git repo like git://host/path/to.git" do
      @homesick.should_receive(:git_clone).with('git://github.com/technicalpickles/pickled-vim.git')

      @homesick.clone "git://github.com/technicalpickles/pickled-vim.git"
    end

    it "should clone git repo like git@host:path/to.git" do
      @homesick.should_receive(:git_clone).with('git@github.com:technicalpickles/pickled-vim.git')

      @homesick.clone 'git@github.com:technicalpickles/pickled-vim.git'
    end

    it "should clone git repo like http://host/path/to.git" do
      @homesick.should_receive(:git_clone).with('http://github.com/technicalpickles/pickled-vim.git')

      @homesick.clone 'http://github.com/technicalpickles/pickled-vim.git'
    end

    it "should clone a github repo" do
      @homesick.should_receive(:git_clone).with('git://github.com/wfarr/dotfiles.git', :destination => 'wfarr_dotfiles')

      @homesick.clone "wfarr/dotfiles"
    end
  end
end
