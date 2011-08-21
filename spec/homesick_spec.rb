require 'spec_helper' 

describe "homesick" do
  let(:homesick) { Homesick.new }
  before { silence! }

  describe "clone" do
    context "of a file" do
      it "should symlink existing directories" do
        somewhere = create_construct
        local_repo = somewhere.directory('wtf')

        homesick.clone local_repo

        @repos_dir.join("wtf").readlink.should == local_repo
      end

      context "when it exists in a repo directory" do
        before do
          @existing_castle = given_castle("existing_castle")
          @existing_dir = @existing_castle.parent
        end

        it "should not symlink" do
          homesick.should_not_receive(:git_clone)

          homesick.clone @existing_dir.to_s rescue nil
        end

        it "should raise an error" do
          expect { homesick.clone @existing_dir.to_s }.to raise_error(/already cloned/i)
        end
      end
    end

    it "should clone git repo like git://host/path/to.git" do
      homesick.should_receive(:git_clone).with('git://github.com/technicalpickles/pickled-vim.git')

      homesick.clone "git://github.com/technicalpickles/pickled-vim.git"
    end

    it "should clone git repo like git@host:path/to.git" do
      homesick.should_receive(:git_clone).with('git@github.com:technicalpickles/pickled-vim.git')

      homesick.clone 'git@github.com:technicalpickles/pickled-vim.git'
    end

    it "should clone git repo like http://host/path/to.git" do
      homesick.should_receive(:git_clone).with('http://github.com/technicalpickles/pickled-vim.git')

      homesick.clone 'http://github.com/technicalpickles/pickled-vim.git'
    end

    it "should clone git repo like http://host/path/to" do
      homesick.should_receive(:git_clone).with('http://github.com/technicalpickles/pickled-vim')

      homesick.clone 'http://github.com/technicalpickles/pickled-vim'
    end

    it "should clone git repo like host-alias:repos.git" do
      homesick.should_receive(:git_clone).with('gitolite:pickled-vim.git')

      homesick.clone 'gitolite:pickled-vim.git'
    end

    it "should not try to clone a malformed uri like malformed" do
      homesick.should_not_receive(:git_clone)

      homesick.clone 'malformed' rescue nil
    end

    it "should throw an exception when trying to clone a malformed uri like malformed" do
      expect { homesick.clone 'malformed' }.to raise_error
    end

    it "should clone a github repo" do
      homesick.should_receive(:git_clone).with('git://github.com/wfarr/dotfiles.git', :destination => Pathname.new('wfarr/dotfiles'))

      homesick.clone "wfarr/dotfiles"
    end
  end

  describe "symlink" do
    context "for dotfiles" do
      it "links dotfiles from a castle to the home folder" do
        castle = given_castle("glencairn")
        dotfile = castle.file(".some_dotfile")

        homesick.symlink("glencairn")

        @user_dir.join(".some_dotfile").readlink.should == dotfile
      end
    end
  end

  describe "list" do
    it "should say each castle in the castle directory" do
      given_castle('zomg')
      given_castle('zomg', 'wtf/zomg')

      homesick.should_receive(:say_status).with("zomg", "git://github.com/technicalpickles/zomg.git", :cyan)
      homesick.should_receive(:say_status).with("wtf/zomg", "git://github.com/technicalpickles/zomg.git", :cyan)

      homesick.list
    end
  end

  describe "pull" do

    xit "needs testing"

    describe "--all" do
      xit "needs testing"
    end

  end

  describe "track" do
    it "should move the tracked file into the castle" do
      castle = given_castle('castle_repo')

      some_rc_file = @user_dir.file '.some_rc_file'

      homesick.track(some_rc_file.to_s, 'castle_repo')

      tracked_file = castle.join(".some_rc_file")
      tracked_file.should exist

      some_rc_file.readlink.should == tracked_file
    end
  end
end
