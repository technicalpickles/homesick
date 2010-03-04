require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Homesick" do
  it "should clone any git repo" do
    homesick = Homesick.new
    repos_dir = Pathname.new('~/.homesick/repos').expand_path
    homesick.clone "git://github.com/technicalpickles/pickled-vim.git"
    File.directory?("#{repos_dir}/pickled-vim").should == true
  end

  it "should clone a github repo" do
    homesick = Homesick.new
    repos_dir = Pathname.new('~/.homesick/repos').expand_path
    homesick.clone "wfarr/dotfiles"
    File.directory?("#{repos_dir}/wfarr_dotfiles").should == true
  end
end
