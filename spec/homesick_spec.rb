# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'capture-output'

describe Homesick do
  let(:home) { create_construct }
  after { home.destroy! }

  let(:castles) { home.directory('.homesick/repos') }

  let(:homesick) { Homesick.new }

  before { homesick.stub(:repos_dir).and_return(castles) }

  describe 'clone' do
    context 'has a .homesickrc' do
      it 'should run the .homesickrc' do
        somewhere = create_construct
        local_repo = somewhere.directory('some_repo')
        local_repo.file('.homesickrc') do |file|
          file << "File.open(Dir.pwd + '/testing', 'w') { |f| f.print 'testing' }"
        end

        expect($stdout).to receive(:print)
        expect($stdin).to receive(:gets).and_return('y')
        homesick.clone local_repo

        castles.join('some_repo').join('testing').should exist
      end
    end

    context 'of a file' do
      it 'should symlink existing directories' do
        somewhere = create_construct
        local_repo = somewhere.directory('wtf')

        homesick.clone local_repo

        castles.join('wtf').readlink.should == local_repo
      end

      context 'when it exists in a repo directory' do
        before do
          existing_castle = given_castle('existing_castle')
          @existing_dir = existing_castle.parent
        end

        it 'should raise an error' do
          homesick.should_not_receive(:git_clone)
          expect { homesick.clone @existing_dir.to_s }.to raise_error(/already cloned/i)
        end
      end
    end

    it 'should clone git repo like file:///path/to.git' do
      bare_repo = File.join(create_construct.to_s, 'dotfiles.git')
      system "git init --bare #{bare_repo} >/dev/null 2>&1"

      homesick.clone "file://#{bare_repo}"
      File.directory?(File.join(home.to_s, '.homesick/repos/dotfiles')).should be_true
    end

    it 'should clone git repo like git://host/path/to.git' do
      homesick.should_receive(:git_clone).with('git://github.com/technicalpickles/pickled-vim.git')

      homesick.clone 'git://github.com/technicalpickles/pickled-vim.git'
    end

    it 'should clone git repo like git@host:path/to.git' do
      homesick.should_receive(:git_clone).with('git@github.com:technicalpickles/pickled-vim.git')

      homesick.clone 'git@github.com:technicalpickles/pickled-vim.git'
    end

    it 'should clone git repo like http://host/path/to.git' do
      homesick.should_receive(:git_clone).with('http://github.com/technicalpickles/pickled-vim.git')

      homesick.clone 'http://github.com/technicalpickles/pickled-vim.git'
    end

    it 'should clone git repo like http://host/path/to' do
      homesick.should_receive(:git_clone).with('http://github.com/technicalpickles/pickled-vim')

      homesick.clone 'http://github.com/technicalpickles/pickled-vim'
    end

    it 'should clone git repo like host-alias:repos.git' do
      homesick.should_receive(:git_clone).with('gitolite:pickled-vim.git')

      homesick.clone 'gitolite:pickled-vim.git'
    end

    it 'should throw an exception when trying to clone a malformed uri like malformed' do
      homesick.should_not_receive(:git_clone)
      expect { homesick.clone 'malformed' }.to raise_error
    end

    it 'should clone a github repo' do
      homesick.should_receive(:git_clone).with('https://github.com/wfarr/dotfiles.git', :destination => Pathname.new('dotfiles'))

      homesick.clone 'wfarr/dotfiles'
    end
  end

  describe 'rc' do
    let(:castle) { given_castle('glencairn') }

    context 'when told to do so' do
      before do
        expect($stdout).to receive(:print)
        expect($stdin).to receive(:gets).and_return('y')
      end

      it 'executes the .homesickrc' do
        castle.file('.homesickrc') do |file|
          file << "File.open(Dir.pwd + '/testing', 'w') { |f| f.print 'testing' }"
        end

        homesick.rc castle

        castle.join('testing').should exist
      end
    end

    context 'when told not to do so' do
      before do
        expect($stdout).to receive(:print)
        expect($stdin).to receive(:gets).and_return('n')
      end

      it 'does not execute the .homesickrc' do
        castle.file('.homesickrc') do |file|
          file << "File.open(Dir.pwd + '/testing', 'w') { |f| f.print 'testing' }"
        end

        homesick.rc castle

        castle.join('testing').should_not exist
      end
    end
  end

  describe 'symlink' do
    let(:castle) { given_castle('glencairn') }

    it 'links dotfiles from a castle to the home folder' do
      dotfile = castle.file('.some_dotfile')

      homesick.symlink('glencairn')

      home.join('.some_dotfile').readlink.should == dotfile
    end

    it 'links non-dotfiles from a castle to the home folder' do
      dotfile = castle.file('bin')

      homesick.symlink('glencairn')

      home.join('bin').readlink.should == dotfile
    end

    context 'when forced' do
      let(:homesick) { Homesick.new [], :force => true }

      it 'can override symlinks to directories' do
        somewhere_else = create_construct
        existing_dotdir_link = home.join('.vim')
        FileUtils.ln_s somewhere_else, existing_dotdir_link

        dotdir = castle.directory('.vim')

        homesick.symlink('glencairn')

        existing_dotdir_link.readlink.should == dotdir
      end

      it 'can override existing directory' do
        existing_dotdir = home.directory('.vim')

        dotdir = castle.directory('.vim')

        homesick.symlink('glencairn')

        existing_dotdir.readlink.should == dotdir
      end
    end

    context "with '.config' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config']) }
      it 'can symlink in sub directory' do
        dotdir = castle.directory('.config')
        dotfile = dotdir.file('.some_dotfile')

        homesick.symlink('glencairn')

        home_dotdir = home.join('.config')
        home_dotdir.symlink?.should be == false
        home_dotdir.join('.some_dotfile').readlink.should == dotfile
      end
    end

    context "with '.config/appA' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config/appA']) }
      it 'can symlink in nested sub directory' do
        dotdir = castle.directory('.config').directory('appA')
        dotfile = dotdir.file('.some_dotfile')

        homesick.symlink('glencairn')

        home_dotdir = home.join('.config').join('appA')
        home_dotdir.symlink?.should be == false
        home_dotdir.join('.some_dotfile').readlink.should == dotfile
      end
    end

    context "with '.config' and '.config/someapp' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config', '.config/someapp']) }
      it 'can symlink under both of .config and .config/someapp' do
        config_dir = castle.directory('.config')
        config_dotfile = config_dir.file('.some_dotfile')
        someapp_dir = config_dir.directory('someapp')
        someapp_dotfile = someapp_dir.file('.some_appfile')

        homesick.symlink('glencairn')

        home_config_dir = home.join('.config')
        home_someapp_dir = home_config_dir.join('someapp')
        home_config_dir.symlink?.should be == false
        home_config_dir.join('.some_dotfile').readlink.should be == config_dotfile
        home_someapp_dir.symlink?.should be == false
        home_someapp_dir.join('.some_appfile').readlink.should == someapp_dotfile
      end
    end

    context "when call with no castle name" do
      let(:castle) { given_castle('dotfiles') }
      it 'using default castle name: "dotfiles"' do
        dotfile = castle.file('.some_dotfile')

        homesick.symlink

        home.join('.some_dotfile').readlink.should == dotfile
      end
    end
  end

  describe 'unlink' do
    let(:castle) { given_castle('glencairn') }

    it 'unlinks dotfiles in the home folder' do
      castle.file('.some_dotfile')

      homesick.symlink('glencairn')
      homesick.unlink('glencairn')

      home.join('.some_dotfile').should_not exist
    end

    it 'unlinks non-dotfiles from the home folder' do
      castle.file('bin')

      homesick.symlink('glencairn')
      homesick.unlink('glencairn')

      home.join('bin').should_not exist
    end

    context "with '.config' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config']) }

      it 'can unlink sub directories' do
        castle.directory('.config').file('.some_dotfile')

        homesick.symlink('glencairn')
        homesick.unlink('glencairn')

        home_dotdir = home.join('.config')
        home_dotdir.should exist
        home_dotdir.join('.some_dotfile').should_not exist
      end
    end

    context "with '.config/appA' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config/appA']) }

      it 'can unsymlink in nested sub directory' do
        castle.directory('.config').directory('appA').file('.some_dotfile')

        homesick.symlink('glencairn')
        homesick.unlink('glencairn')

        home_dotdir = home.join('.config').join('appA')
        home_dotdir.should exist
        home_dotdir.join('.some_dotfile').should_not exist
      end
    end

    context "with '.config' and '.config/someapp' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config', '.config/someapp']) }

      it 'can unsymlink under both of .config and .config/someapp' do
        config_dir = castle.directory('.config')
        config_dir.file('.some_dotfile')
        config_dir.directory('someapp').file('.some_appfile')

        homesick.symlink('glencairn')
        homesick.unlink('glencairn')

        home_config_dir = home.join('.config')
        home_someapp_dir = home_config_dir.join('someapp')
        home_config_dir.should exist
        home_config_dir.join('.some_dotfile').should_not exist
        home_someapp_dir.should exist
        home_someapp_dir.join('.some_appfile').should_not exist
      end
    end

    context "when call with no castle name" do
      let(:castle) { given_castle('dotfiles') }

      it 'using default castle name: "dotfiles"' do
        castle.file('.some_dotfile')

        homesick.symlink
        homesick.unlink

        home.join('.some_dotfile').should_not exist
      end
    end
  end

  describe 'list' do
    it 'should say each castle in the castle directory' do
      given_castle('zomg')
      given_castle('wtf/zomg')

      homesick.should_receive(:say_status).with('zomg', 'git://github.com/technicalpickles/zomg.git', :cyan)
      homesick.should_receive(:say_status).with('wtf/zomg', 'git://github.com/technicalpickles/zomg.git', :cyan)

      homesick.list
    end
  end

  describe 'status' do
    it 'should say "nothing to commit" when there are no changes' do
      given_castle('castle_repo')
      text = Capture.stdout { homesick.status('castle_repo') }
      text.should =~ /nothing to commit \(create\/copy files and use "git add" to track\)$/
    end

    it 'should say "Changes to be committed" when there are changes' do
      given_castle('castle_repo')
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, 'castle_repo')
      text = Capture.stdout { homesick.status('castle_repo') }
      text.should =~ /Changes to be committed:.*new file:\s*home\/.some_rc_file/m
    end
  end

  describe 'diff' do

    xit 'needs testing'

  end

  describe 'show_path' do
    it 'should say the path of a castle' do
      castle = given_castle('castle_repo')

      homesick.should_receive(:say).with(castle.dirname)

      homesick.show_path('castle_repo')
    end
  end

  describe 'pull' do

    xit 'needs testing'

    describe '--all' do
      xit 'needs testing'
    end

  end

  describe 'push' do

    xit 'needs testing'

  end

  describe 'track' do
    it 'should move the tracked file into the castle' do
      castle = given_castle('castle_repo')

      some_rc_file = home.file '.some_rc_file'

      homesick.track(some_rc_file.to_s, 'castle_repo')

      tracked_file = castle.join('.some_rc_file')
      tracked_file.should exist

      some_rc_file.readlink.should == tracked_file
    end

    it 'should handle files with parens' do
      castle = given_castle('castle_repo')

      some_rc_file = home.file 'Default (Linux).sublime-keymap'

      homesick.track(some_rc_file.to_s, 'castle_repo')

      tracked_file = castle.join('Default (Linux).sublime-keymap')
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

    context "when call with no castle name" do
      it 'using default castle name: "dotfiles"' do
        castle = given_castle('dotfiles')

        some_rc_file = home.file '.some_rc_file'

        homesick.track(some_rc_file.to_s)

        tracked_file = castle.join('.some_rc_file')
        tracked_file.should exist

        some_rc_file.readlink.should == tracked_file
      end
    end

    describe 'commit' do
      it 'should have a commit message when the commit succeeds' do
        given_castle('castle_repo')
        some_rc_file = home.file '.a_random_rc_file'
        homesick.track(some_rc_file.to_s, 'castle_repo')
        text = Capture.stdout { homesick.commit('castle_repo', 'Test message') }
        text.should =~ /^\[master \(root-commit\) \w+\] Test message/
      end
    end

    describe 'subdir_file' do

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
      expect_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return('y')
      given_castle("stronghold")
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, "stronghold")
      homesick.destroy('stronghold')

      some_rc_file.should_not be_exist
    end

    it "deletes the cloned repository" do
      expect_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return('y')
      castle = given_castle("stronghold")
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, "stronghold")
      homesick.destroy('stronghold')

      castle.should_not be_exist
    end
  end

  describe "cd" do
    it "cd's to the root directory of the given castle" do
      given_castle('castle_repo')
      homesick.should_receive("inside").once.with(kind_of(Pathname)).and_yield
      homesick.should_receive("system").once.with(ENV["SHELL"])
      Capture.stdout { homesick.cd 'castle_repo' }
    end

    it "returns an error message when the given castle does not exist" do
      homesick.should_receive("say_status").once.with(:error, /Could not cd castle_repo, expected \/tmp\/construct_container.* exist and contain dotfiles/, :red)
      expect { homesick.cd "castle_repo" }.to raise_error(SystemExit)
    end
  end

  describe "open" do
    it "opens the system default editor in the root of the given castle" do
      ENV.stub(:[]).and_call_original # Make sure calls to ENV use default values for most things...
      ENV.stub(:[]).with('EDITOR').and_return('vim') # Set a default value for 'EDITOR' just in case none is set
      given_castle 'castle_repo'
      homesick.should_receive("inside").once.with(kind_of(Pathname)).and_yield
      homesick.should_receive("system").once.with('vim')
      Capture.stdout { homesick.open 'castle_repo' }
    end

    it "returns an error message when the $EDITOR environment variable is not set" do
      ENV.stub(:[]).with('EDITOR').and_return(nil) # Set the default editor to make sure it fails.
      homesick.should_receive("say_status").once.with(:error,"The $EDITOR environment variable must be set to use this command", :red)
      expect { homesick.open "castle_repo" }.to raise_error(SystemExit)
    end

    it "returns an error message when the given castle does not exist" do
      ENV.stub(:[]).with('EDITOR').and_return('vim') # Set a default just in case none is set
      homesick.should_receive("say_status").once.with(:error, /Could not open castle_repo, expected \/tmp\/construct_container.* exist and contain dotfiles/, :red)
      expect { homesick.open "castle_repo" }.to raise_error(SystemExit)
    end
  end

  describe 'version' do
    it 'should print the current version of homesick' do
      text = Capture.stdout { homesick.version }
      text.chomp.should =~ /\d+\.\d+\.\d+/
    end
  end
end
