require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Homesick" do
  it "should clone a git repo" do
    homesick = Homesick.new
    homesick.clone "git://github.com/technicalpickles/pickled-vim.git"
    File.directory?("#{Pathname.new('~/.homesick/repos').expand_path}/pickled-vim").should == true
  end

  it "should clone the github repo" do
    homesick = Homesick.new
    homesick.clone "wfarr/dotfiles"
    File.directory?("#{Pathname.new('~/.homesick/repos').expand_path}/wfarr_dotfiles").should == true
  end
end
