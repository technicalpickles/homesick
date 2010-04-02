require 'spec_helper'

describe Homesick do
  before do
    @homesick = Homesick.new
  end

  it "should clone any git repo" do
    @homesick.should_receive(:git_clone).with('git://github.com/technicalpickles/pickled-vim.git')

    @homesick.clone "git://github.com/technicalpickles/pickled-vim.git"
  end

  it "should clone a github repo" do
    @homesick.should_receive(:git_clone).with('git://github.com/wfarr/dotfiles.git', :destination => 'wfarr_dotfiles')

    @homesick.clone "wfarr/dotfiles"
  end
end
