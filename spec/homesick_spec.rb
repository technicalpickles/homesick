require 'spec_helper'

describe 'homesick' do
  let(:home) { create_construct }
  after { home.destroy! }

  let(:castles) { home.directory('.homesick/repos') }

  let(:homesick) { Homesick::CLI.new }

  before { homesick.stub(:repos_dir).and_return(castles) }

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
      let(:homesick) { Homesick::CLI.new [], :force => true }

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

    xit 'needs testing'

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

  describe 'commit' do

    xit 'needs testing'

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

    describe 'subdir_file' do

      it 'should add the nested files parent to the subdir_file' do
        castle = given_castle('castle_repo')

        some_nested_file = home.file('some/nested/file.txt')
        homesick.track(some_nested_file.to_s, 'castle_repo')

        subdir_file = castle.parent.join(Homesick::CLI::SUBDIR_FILENAME)
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

        subdir_file = castle.parent.join(Homesick::CLI::SUBDIR_FILENAME)
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

        subdir_file = castle.parent.join(Homesick::CLI::SUBDIR_FILENAME)
        File.open(subdir_file, 'r') do |f|
          f.each_line { |line| line.should_not == "some/nested\n" }
        end
      end
    end
  end
end
