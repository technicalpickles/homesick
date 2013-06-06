# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "homesick" do
  let(:home) { create_construct }
  after { home.destroy! }

  let(:castles) { home.directory(".homesick/repos") }

  let(:homesick) { Homesick.new }

  before { homesick.stub!(:repos_dir).and_return(castles) }

  describe "clone" do
    context "of a file" do
      it "should symlink existing directories" do
        somewhere = create_construct
        local_repo = somewhere.directory('wtf')

        homesick.clone local_repo

        castles.join("wtf").readlink.should == local_repo
      end

      context "when it exists in a repo directory" do
        before do
          existing_castle = given_castle("existing_castle")
          @existing_dir = existing_castle.parent
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
    let(:castle) { given_castle("glencairn") }

    it "links dotfiles from a castle to the home folder" do
      dotfile = castle.file(".some_dotfile")

      homesick.symlink("glencairn")

      home.join(".some_dotfile").readlink.should == dotfile
    end

    it "links non-dotfiles from a castle to the home folder" do
      dotfile = castle.file("bin")

      homesick.symlink("glencairn")

      home.join("bin").readlink.should == dotfile
    end

    context "when forced" do
      let(:homesick) { Homesick.new [], :force => true }

      it "can override symlinks to directories" do
        somewhere_else = create_construct
        existing_dotdir_link = home.join(".vim")
        FileUtils.ln_s somewhere_else, existing_dotdir_link

        dotdir = castle.directory(".vim")

        homesick.symlink("glencairn")

        existing_dotdir_link.readlink.should == dotdir
      end
    end

    context "with '.config' in .homesick_subdir" do
      let(:castle) { given_castle("glencairn", [".config"]) }
      it "can symlink in sub directory" do
        dotdir = castle.directory(".config")
        dotfile = dotdir.file(".some_dotfile")

        homesick.symlink("glencairn")

        home_dotdir = home.join(".config")
        home_dotdir.symlink?.should == false
        home_dotdir.join(".some_dotfile").readlink.should == dotfile
      end
    end

    context "with '.config/appA' in .homesick_subdir" do
      let(:castle) { given_castle("glencairn", [".config/appA"]) }
      it "can symlink in nested sub directory" do
        dotdir = castle.directory(".config").directory("appA")
        dotfile = dotdir.file(".some_dotfile")

        homesick.symlink("glencairn")

        home_dotdir = home.join(".config").join("appA")
        home_dotdir.symlink?.should == false
        home_dotdir.join(".some_dotfile").readlink.should == dotfile
      end
    end

    context "with '.config' and '.config/appA' in .homesick_subdir" do
      let(:castle) { given_castle("glencairn", [".config", ".config/appA"]) }
      it "can symlink under both of .config and .config/appA" do
        config_dir = castle.directory(".config")
        config_dotfile = config_dir.file(".some_dotfile")
        appA_dir = config_dir.directory("appA")
        appA_dotfile = appA_dir.file(".some_appfile")

        homesick.symlink("glencairn")

        home_config_dir = home.join(".config")
        home_appA_dir = home_config_dir.join("appA")
        home_config_dir.symlink?.should == false
        home_config_dir.join(".some_dotfile").readlink.should == config_dotfile
        home_appA_dir.symlink?.should == false
        home_appA_dir.join(".some_appfile").readlink.should == appA_dotfile
      end
    end
  end

  describe "list" do
    it "should say each castle in the castle directory" do
      given_castle('zomg')
      given_castle('wtf/zomg')

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

  describe "commit" do

    xit "needs testing"

  end

  describe "push" do

    xit "needs testing"

  end

  describe "track" do
    it "should move the tracked file into the castle" do
      castle = given_castle('castle_repo')

      some_rc_file = home.file '.some_rc_file'

      homesick.track(some_rc_file.to_s, 'castle_repo')

      tracked_file = castle.join(".some_rc_file")
      tracked_file.should exist

      some_rc_file.readlink.should == tracked_file
    end

    it 'should track a file in nested folder structure' do
      castle = given_castle('castle_repo')

      some_nested_file = home.file('some/nested/file.txt')
      homesick.track(some_nested_file.to_s, 'castle_repo')

      tracked_file = castle.join('some/nested/file.txt')
      tracked_file.should exist
      some_nested_file.readlink.should == tracked_file
    end

    it 'should track a nested directory' do
      castle = given_castle('castle_repo')

      some_nested_dir = home.directory('some/nested/directory/')
      homesick.track(some_nested_dir.to_s, 'castle_repo')

      tracked_file = castle.join('some/nested/directory/')
      tracked_file.should exist
      some_nested_dir.realpath.should == tracked_file.realpath
    end

    describe "subdir_file" do

      it 'should add the nested files parent to the subdir_file' do
        castle = given_castle('castle_repo')

        some_nested_file = home.file('some/nested/file.txt')
        homesick.track(some_nested_file.to_s, 'castle_repo')

        subdir_file = castle.parent.join(Homesick::SUBDIR_FILENAME)
        File.open(subdir_file, 'r') do |f|
          f.readline.should == "some/nested\n"
        end
      end

      it 'should NOT add anything if the files parent is already listed' do
        castle = given_castle('castle_repo')

        some_nested_file = home.file('some/nested/file.txt')
        other_nested_file = home.file('some/nested/other.txt')
        homesick.track(some_nested_file.to_s, 'castle_repo')
        homesick.track(other_nested_file.to_s, 'castle_repo')

        subdir_file = castle.parent.join(Homesick::SUBDIR_FILENAME)
        File.open(subdir_file, 'r') do |f|
          f.readlines.size.should == 1
        end
      end

      it 'should remove the parent of a tracked file from the subdir_file if the parent itself is tracked' do
        castle = given_castle('castle_repo')

        some_nested_file = home.file('some/nested/file.txt')
        nested_parent = home.directory('some/nested/')
        homesick.track(some_nested_file.to_s, 'castle_repo')
        homesick.track(nested_parent.to_s, 'castle_repo')

        subdir_file = castle.parent.join(Homesick::SUBDIR_FILENAME)
        File.open(subdir_file, 'r') do |f|
          f.each_line { |line| line.should_not == "some/nested\n" }
        end
      end
    end
  end

  describe "destroy" do
    it "removes the symlink files" do
      given_castle("stronghold")
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, "stronghold")
      homesick.destroy('stronghold')

      some_rc_file.should_not be_exist
    end

    it "deletes the cloned repository" do
      castle = given_castle("stronghold")
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, "stronghold")
      homesick.destroy('stronghold')

      castle.should_not be_exist
    end
  end
end
