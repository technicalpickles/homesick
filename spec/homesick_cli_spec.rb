# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'capture-output'
require 'pathname'

describe Homesick::CLI do
  let(:home) { create_construct }
  after { home.destroy! }

  let(:castles) { home.directory('.homesick/repos') }

  let(:homesick) { Homesick::CLI.new }

  before { allow(homesick).to receive(:repos_dir).and_return(castles) }

  describe 'smoke tests' do
    context 'when running bin/homesick' do
      before do
        bin_path = Pathname.new(__FILE__).parent.parent
        @output = `#{bin_path.expand_path}/bin/homesick`
      end
      it 'should output some text when bin/homesick is called' do
        expect(@output.length).to be > 0
      end
    end

    context 'when git is not installed' do
      before do
        expect_any_instance_of(Homesick::Actions::GitActions).to receive(:`).and_return("git version 1.0.0")
      end
      it 'should raise an exception when' do
        output = Capture.stdout{ expect{Homesick::CLI.new}.to raise_error SystemExit }
        expect(output.chomp).to include(Homesick::Actions::GitActions::STRING)
      end
    end

    context 'when git is installed' do
      before do
        expect_any_instance_of(Homesick::Actions::GitActions).to receive(:`).at_least(:once).and_return("git version #{Homesick::Actions::GitActions::STRING}")
      end
      it 'should not raise an exception' do
        output = Capture.stdout{ expect{Homesick::CLI.new}.not_to raise_error }
        expect(output.chomp).not_to include(Homesick::Actions::GitActions::STRING)
      end
    end
  end

  describe 'clone' do
    context 'has a .homesickrc' do
      it 'runs the .homesickrc' do
        somewhere = create_construct
        local_repo = somewhere.directory('some_repo')
        local_repo.file('.homesickrc') do |file|
          file << "File.open(Dir.pwd + '/testing', 'w') do |f|
            f.print 'testing'
          end"
        end

        expect_any_instance_of(Thor::Shell::Basic).to receive(:yes?).with(be_a(String)).and_return(true)
        expect(homesick).to receive(:say_status).with('eval', kind_of(Pathname))
        homesick.clone local_repo

        expect(castles.join('some_repo').join('testing')).to exist
      end
    end

    context 'of a file' do
      it 'symlinks existing directories' do
        somewhere = create_construct
        local_repo = somewhere.directory('wtf')

        homesick.clone local_repo

        expect(castles.join('wtf').readlink).to eq(local_repo)
      end

      context 'when it exists in a repo directory' do
        before do
          existing_castle = given_castle('existing_castle')
          @existing_dir = existing_castle.parent
        end

        it 'raises an error' do
          expect(homesick).not_to receive(:git_clone)
          expect { homesick.clone @existing_dir.to_s }.to raise_error(/already cloned/i)
        end
      end
    end

    it 'clones git repo like file:///path/to.git' do
      bare_repo = File.join(create_construct.to_s, 'dotfiles.git')
      system "git init --bare #{bare_repo} >/dev/null 2>&1"

      # Capture stderr to suppress message about cloning an empty repo.
      Capture.stderr do
        homesick.clone "file://#{bare_repo}"
      end
      expect(File.directory?(File.join(home.to_s, '.homesick/repos/dotfiles')))
        .to be_truthy
    end

    it 'clones git repo like git://host/path/to.git' do
      expect(homesick).to receive(:git_clone)
              .with('git://github.com/technicalpickles/pickled-vim.git')

      homesick.clone 'git://github.com/technicalpickles/pickled-vim.git'
    end

    it 'clones git repo like git@host:path/to.git' do
      expect(homesick).to receive(:git_clone)
              .with('git@github.com:technicalpickles/pickled-vim.git')

      homesick.clone 'git@github.com:technicalpickles/pickled-vim.git'
    end

    it 'clones git repo like http://host/path/to.git' do
      expect(homesick).to receive(:git_clone)
              .with('http://github.com/technicalpickles/pickled-vim.git')

      homesick.clone 'http://github.com/technicalpickles/pickled-vim.git'
    end

    it 'clones git repo like http://host/path/to' do
      expect(homesick).to receive(:git_clone)
              .with('http://github.com/technicalpickles/pickled-vim')

      homesick.clone 'http://github.com/technicalpickles/pickled-vim'
    end

    it 'clones git repo like host-alias:repos.git' do
      expect(homesick).to receive(:git_clone).with('gitolite:pickled-vim.git')

      homesick.clone 'gitolite:pickled-vim.git'
    end

    it 'throws an exception when trying to clone a malformed uri like malformed' do
      expect(homesick).not_to receive(:git_clone)
      expect { homesick.clone 'malformed' }.to raise_error
    end

    it 'clones a github repo' do
      expect(homesick).to receive(:git_clone)
              .with('https://github.com/wfarr/dotfiles.git',
                    destination: Pathname.new('dotfiles'))

      homesick.clone 'wfarr/dotfiles'
    end
  end

  describe 'rc' do
    let(:castle) { given_castle('glencairn') }

    context 'when told to do so' do
      before do
        expect_any_instance_of(Thor::Shell::Basic).to receive(:yes?).with(be_a(String)).and_return(true)
      end

      it 'executes the .homesickrc' do
        castle.file('.homesickrc') do |file|
          file << "File.open(Dir.pwd + '/testing', 'w') do |f|
            f.print 'testing'
          end"
        end

        expect(homesick).to receive(:say_status).with('eval', kind_of(Pathname))
        homesick.rc castle

        expect(castle.join('testing')).to exist
      end
    end

    context 'when options[:force] == true' do
      let(:homesick) { Homesick::CLI.new [], force: true }
      before do
        expect_any_instance_of(Thor::Shell::Basic).to_not receive(:yes?)
      end

      it 'executes the .homesickrc' do
        castle.file('.homesickrc') do |file|
          file << "File.open(Dir.pwd + '/testing', 'w') do |f|
            f.print 'testing'
          end"
        end

        expect(homesick).to receive(:say_status).with('eval', kind_of(Pathname))
        homesick.rc castle

        expect(castle.join('testing')).to exist
      end
    end

    context 'when told not to do so' do
      before do
        expect_any_instance_of(Thor::Shell::Basic).to receive(:yes?).with(be_a(String)).and_return(false)
      end

      it 'does not execute the .homesickrc' do
        castle.file('.homesickrc') do |file|
          file << "File.open(Dir.pwd + '/testing', 'w') do |f|
            f.print 'testing'
          end"
        end

        expect(homesick).to receive(:say_status).with('eval skip', /not evaling.+/, :blue)
        homesick.rc castle

        expect(castle.join('testing')).not_to exist
      end
    end
  end

  describe 'link' do
    let(:castle) { given_castle('glencairn') }

    it 'links dotfiles from a castle to the home folder' do
      dotfile = castle.file('.some_dotfile')

      homesick.link('glencairn')

      expect(home.join('.some_dotfile').readlink).to eq(dotfile)
    end

    it 'links non-dotfiles from a castle to the home folder' do
      dotfile = castle.file('bin')

      homesick.link('glencairn')

      expect(home.join('bin').readlink).to eq(dotfile)
    end

    context 'when forced' do
      let(:homesick) { Homesick::CLI.new [], force: true }

      it 'can override symlinks to directories' do
        somewhere_else = create_construct
        existing_dotdir_link = home.join('.vim')
        FileUtils.ln_s somewhere_else, existing_dotdir_link

        dotdir = castle.directory('.vim')

        homesick.link('glencairn')

        expect(existing_dotdir_link.readlink).to eq(dotdir)
      end

      it 'can override existing directory' do
        existing_dotdir = home.directory('.vim')

        dotdir = castle.directory('.vim')

        homesick.link('glencairn')

        expect(existing_dotdir.readlink).to eq(dotdir)
      end
    end

    context "with '.config' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config']) }
      it 'can symlink in sub directory' do
        dotdir = castle.directory('.config')
        dotfile = dotdir.file('.some_dotfile')

        homesick.link('glencairn')

        home_dotdir = home.join('.config')
        expect(home_dotdir.symlink?).to eq(false)
        expect(home_dotdir.join('.some_dotfile').readlink).to eq(dotfile)
      end
    end

    context "with '.config/appA' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config/appA']) }
      it 'can symlink in nested sub directory' do
        dotdir = castle.directory('.config').directory('appA')
        dotfile = dotdir.file('.some_dotfile')

        homesick.link('glencairn')

        home_dotdir = home.join('.config').join('appA')
        expect(home_dotdir.symlink?).to eq(false)
        expect(home_dotdir.join('.some_dotfile').readlink).to eq(dotfile)
      end
    end

    context "with '.config' and '.config/someapp' in .homesick_subdir" do
      let(:castle) do
        given_castle('glencairn', ['.config', '.config/someapp'])
      end
      it 'can symlink under both of .config and .config/someapp' do
        config_dir = castle.directory('.config')
        config_dotfile = config_dir.file('.some_dotfile')
        someapp_dir = config_dir.directory('someapp')
        someapp_dotfile = someapp_dir.file('.some_appfile')

        homesick.link('glencairn')

        home_config_dir = home.join('.config')
        home_someapp_dir = home_config_dir.join('someapp')
        expect(home_config_dir.symlink?).to eq(false)
        expect(home_config_dir.join('.some_dotfile').readlink)
                       .to eq(config_dotfile)
        expect(home_someapp_dir.symlink?).to eq(false)
        expect(home_someapp_dir.join('.some_appfile').readlink)
                        .to eq(someapp_dotfile)
      end
    end

    context 'when call with no castle name' do
      let(:castle) { given_castle('dotfiles') }
      it 'using default castle name: "dotfiles"' do
        dotfile = castle.file('.some_dotfile')

        homesick.link

        expect(home.join('.some_dotfile').readlink).to eq(dotfile)
      end
    end
  end

  describe 'unlink' do
    let(:castle) { given_castle('glencairn') }

    it 'unlinks dotfiles in the home folder' do
      castle.file('.some_dotfile')

      homesick.link('glencairn')
      homesick.unlink('glencairn')

      expect(home.join('.some_dotfile')).not_to exist
    end

    it 'unlinks non-dotfiles from the home folder' do
      castle.file('bin')

      homesick.link('glencairn')
      homesick.unlink('glencairn')

      expect(home.join('bin')).not_to exist
    end

    context "with '.config' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config']) }

      it 'can unlink sub directories' do
        castle.directory('.config').file('.some_dotfile')

        homesick.link('glencairn')
        homesick.unlink('glencairn')

        home_dotdir = home.join('.config')
        expect(home_dotdir).to exist
        expect(home_dotdir.join('.some_dotfile')).not_to exist
      end
    end

    context "with '.config/appA' in .homesick_subdir" do
      let(:castle) { given_castle('glencairn', ['.config/appA']) }

      it 'can unsymlink in nested sub directory' do
        castle.directory('.config').directory('appA').file('.some_dotfile')

        homesick.link('glencairn')
        homesick.unlink('glencairn')

        home_dotdir = home.join('.config').join('appA')
        expect(home_dotdir).to exist
        expect(home_dotdir.join('.some_dotfile')).not_to exist
      end
    end

    context "with '.config' and '.config/someapp' in .homesick_subdir" do
      let(:castle) do
        given_castle('glencairn', ['.config', '.config/someapp'])
      end

      it 'can unsymlink under both of .config and .config/someapp' do
        config_dir = castle.directory('.config')
        config_dir.file('.some_dotfile')
        config_dir.directory('someapp').file('.some_appfile')

        homesick.link('glencairn')
        homesick.unlink('glencairn')

        home_config_dir = home.join('.config')
        home_someapp_dir = home_config_dir.join('someapp')
        expect(home_config_dir).to exist
        expect(home_config_dir.join('.some_dotfile')).not_to exist
        expect(home_someapp_dir).to exist
        expect(home_someapp_dir.join('.some_appfile')).not_to exist
      end
    end

    context 'when call with no castle name' do
      let(:castle) { given_castle('dotfiles') }

      it 'using default castle name: "dotfiles"' do
        castle.file('.some_dotfile')

        homesick.link
        homesick.unlink

        expect(home.join('.some_dotfile')).not_to exist
      end
    end
  end

  describe 'list' do
    it 'says each castle in the castle directory' do
      given_castle('zomg')
      given_castle('wtf/zomg')

      expect(homesick).to receive(:say_status)
              .with('zomg',
                    'git://github.com/technicalpickles/zomg.git',
                    :cyan)
      expect(homesick).to receive(:say_status)
              .with('wtf/zomg',
                    'git://github.com/technicalpickles/zomg.git',
                    :cyan)

      homesick.list
    end
  end

  describe 'status' do
    it 'says "nothing to commit" when there are no changes' do
      given_castle('castle_repo')
      text = Capture.stdout { homesick.status('castle_repo') }
      expect(text).to match(/nothing to commit \(create\/copy files and use "git add" to track\)$/)
    end

    it 'says "Changes to be committed" when there are changes' do
      given_castle('castle_repo')
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, 'castle_repo')
      text = Capture.stdout { homesick.status('castle_repo') }
      expect(text).to match(
        /Changes to be committed:.*new file:\s*home\/.some_rc_file/m
      )
    end
  end

  describe 'diff' do
    it 'outputs an empty message when there are no changes to commit' do
      given_castle('castle_repo')
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, 'castle_repo')
      Capture.stdout do
        homesick.commit 'castle_repo', 'Adding a file to the test'
      end
      text = Capture.stdout { homesick.diff('castle_repo') }
      expect(text).to eq('')
    end

    it 'outputs a diff message when there are changes to commit' do
      given_castle('castle_repo')
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, 'castle_repo')
      Capture.stdout do
        homesick.commit 'castle_repo', 'Adding a file to the test'
      end
      File.open(some_rc_file.to_s, 'w') do |file|
        file.puts 'Some test text'
      end
      text = Capture.stdout { homesick.diff('castle_repo') }
      expect(text).to match(/diff --git.+Some test text$/m)
    end
  end

  describe 'show_path' do
    it 'says the path of a castle' do
      castle = given_castle('castle_repo')

      expect(homesick).to receive(:say).with(castle.dirname)

      homesick.show_path('castle_repo')
    end
  end

  describe 'pull' do
    it 'performs a pull, submodule init and update when the given castle exists' do
      given_castle('castle_repo')
      allow(homesick).to receive(:system).once.with('git pull --quiet')
      allow(homesick).to receive(:system).once.with('git submodule --quiet init')
      allow(homesick).to receive(:system).once.with('git submodule --quiet update --init --recursive >/dev/null 2>&1')
      homesick.pull 'castle_repo'
    end

    it 'prints an error message when trying to pull a non-existant castle' do
      expect(homesick).to receive('say_status').once
        .with(:error,
              /Could not pull castle_repo, expected .* exist and contain dotfiles/,
              :red)
      expect { homesick.pull 'castle_repo' }.to raise_error(SystemExit)
    end

    describe '--all' do
      it 'pulls each castle when invoked with --all' do
        given_castle('castle_repo')
        given_castle('glencairn')
        allow(homesick).to receive(:system).exactly(2).times.with('git pull --quiet')
        allow(homesick).to receive(:system).exactly(2).times
          .with('git submodule --quiet init')
        allow(homesick).to receive(:system).exactly(2).times
          .with('git submodule --quiet update --init --recursive >/dev/null 2>&1')
        Capture.stdout do
          Capture.stderr { homesick.invoke 'pull', [], all: true }
        end
      end
    end

  end

  describe 'push' do
    it 'performs a git push on the given castle' do
      given_castle('castle_repo')
      allow(homesick).to receive(:system).once.with('git push')
      homesick.push 'castle_repo'
    end

    it 'prints an error message when trying to push a non-existant castle' do
      expect(homesick).to receive('say_status').once
              .with(:error,
                    /Could not push castle_repo, expected .* exist and contain dotfiles/,
                    :red)
      expect { homesick.push 'castle_repo' }.to raise_error(SystemExit)
    end
  end

  describe 'track' do
    it 'moves the tracked file into the castle' do
      castle = given_castle('castle_repo')

      some_rc_file = home.file '.some_rc_file'

      homesick.track(some_rc_file.to_s, 'castle_repo')

      tracked_file = castle.join('.some_rc_file')
      expect(tracked_file).to exist

      expect(some_rc_file.readlink).to eq(tracked_file)
    end

    it 'handles files with parens' do
      castle = given_castle('castle_repo')

      some_rc_file = home.file 'Default (Linux).sublime-keymap'

      homesick.track(some_rc_file.to_s, 'castle_repo')

      tracked_file = castle.join('Default (Linux).sublime-keymap')
      expect(tracked_file).to exist

      expect(some_rc_file.readlink).to eq(tracked_file)
    end

    it 'tracks a file in nested folder structure' do
      castle = given_castle('castle_repo')

      some_nested_file = home.file('some/nested/file.txt')
      homesick.track(some_nested_file.to_s, 'castle_repo')

      tracked_file = castle.join('some/nested/file.txt')
      expect(tracked_file).to exist
      expect(some_nested_file.readlink).to eq(tracked_file)
    end

    it 'tracks a nested directory' do
      castle = given_castle('castle_repo')

      some_nested_dir = home.directory('some/nested/directory/')
      homesick.track(some_nested_dir.to_s, 'castle_repo')

      tracked_file = castle.join('some/nested/directory/')
      expect(tracked_file).to exist
      expect(some_nested_dir.realpath).to eq(tracked_file.realpath)
    end

    context 'when call with no castle name' do
      it 'using default castle name: "dotfiles"' do
        castle = given_castle('dotfiles')

        some_rc_file = home.file '.some_rc_file'

        homesick.track(some_rc_file.to_s)

        tracked_file = castle.join('.some_rc_file')
        expect(tracked_file).to exist

        expect(some_rc_file.readlink).to eq(tracked_file)
      end
    end

    describe 'commit' do
      it 'has a commit message when the commit succeeds' do
        given_castle('castle_repo')
        some_rc_file = home.file '.a_random_rc_file'
        homesick.track(some_rc_file.to_s, 'castle_repo')
        text = Capture.stdout do
          homesick.commit('castle_repo', 'Test message')
        end
        expect(text).to match(/^\[master \(root-commit\) \w+\] Test message/)
      end
    end

    # Note that this is a test for the subdir_file related feature of track,
    # not for the subdir_file method itself.
    describe 'subdir_file' do

      it 'adds the nested files parent to the subdir_file' do
        castle = given_castle('castle_repo')

        some_nested_file = home.file('some/nested/file.txt')
        homesick.track(some_nested_file.to_s, 'castle_repo')

        subdir_file = castle.parent.join(Homesick::SUBDIR_FILENAME)
        File.open(subdir_file, 'r') do |f|
          expect(f.readline).to eq("some/nested\n")
        end
      end

      it 'does NOT add anything if the files parent is already listed' do
        castle = given_castle('castle_repo')

        some_nested_file = home.file('some/nested/file.txt')
        other_nested_file = home.file('some/nested/other.txt')
        homesick.track(some_nested_file.to_s, 'castle_repo')
        homesick.track(other_nested_file.to_s, 'castle_repo')

        subdir_file = castle.parent.join(Homesick::SUBDIR_FILENAME)
        File.open(subdir_file, 'r') do |f|
          expect(f.readlines.size).to eq(1)
        end
      end

      it 'removes the parent of a tracked file from the subdir_file if the parent itself is tracked' do
        castle = given_castle('castle_repo')

        some_nested_file = home.file('some/nested/file.txt')
        nested_parent = home.directory('some/nested/')
        homesick.track(some_nested_file.to_s, 'castle_repo')
        homesick.track(nested_parent.to_s, 'castle_repo')

        subdir_file = castle.parent.join(Homesick::SUBDIR_FILENAME)
        File.open(subdir_file, 'r') do |f|
          f.each_line { |line| expect(line).not_to eq("some/nested\n") }
        end
      end
    end
  end

  describe 'destroy' do
    it 'removes the symlink files' do
      expect_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return('y')
      given_castle('stronghold')
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, 'stronghold')
      homesick.destroy('stronghold')

      expect(some_rc_file).not_to be_exist
    end

    it 'deletes the cloned repository' do
      expect_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return('y')
      castle = given_castle('stronghold')
      some_rc_file = home.file '.some_rc_file'
      homesick.track(some_rc_file.to_s, 'stronghold')
      homesick.destroy('stronghold')

      expect(castle).not_to be_exist
    end
  end

  describe 'cd' do
    it "cd's to the root directory of the given castle" do
      given_castle('castle_repo')
      expect(homesick).to receive('inside').once.with(kind_of(Pathname)).and_yield
      expect(homesick).to receive('system').once.with(ENV['SHELL'])
      Capture.stdout { homesick.cd 'castle_repo' }
    end

    it 'returns an error message when the given castle does not exist' do
      expect(homesick).to receive('say_status').once
              .with(:error,
                    /Could not cd castle_repo, expected .* exist and contain dotfiles/,
                    :red)
      expect { homesick.cd 'castle_repo' }.to raise_error(SystemExit)
    end
  end

  describe 'open' do
    it 'opens the system default editor in the root of the given castle' do
      # Make sure calls to ENV use default values for most things...
      allow(ENV).to receive(:[]).and_call_original
      # Set a default value for 'EDITOR' just in case none is set
      allow(ENV).to receive(:[]).with('EDITOR').and_return('vim')
      given_castle 'castle_repo'
      expect(homesick).to receive('inside').once.with(kind_of(Pathname)).and_yield
      expect(homesick).to receive('system').once.with('vim')
      Capture.stdout { homesick.open 'castle_repo' }
    end

    it 'returns an error message when the $EDITOR environment variable is not set' do
      # Set the default editor to make sure it fails.
      allow(ENV).to receive(:[]).with('EDITOR').and_return(nil)
      expect(homesick).to receive('say_status').once
              .with(:error,
                    'The $EDITOR environment variable must be set to use this command',
                    :red)
      expect { homesick.open 'castle_repo' }.to raise_error(SystemExit)
    end

    it 'returns an error message when the given castle does not exist' do
      # Set a default just in case none is set
      allow(ENV).to receive(:[]).with('EDITOR').and_return('vim')
      allow(homesick).to receive('say_status').once
              .with(:error,
                    /Could not open castle_repo, expected .* exist and contain dotfiles/,
                    :red)
      expect { homesick.open 'castle_repo' }.to raise_error(SystemExit)
    end
  end

  describe 'version' do
    it 'prints the current version of homesick' do
      text = Capture.stdout { homesick.version }
      expect(text.chomp).to match(/#{Regexp.escape(Homesick::Version::STRING)}/)
    end
  end

  describe 'exec' do
    before do
      given_castle 'castle_repo'
    end
    it 'executes a single command with no arguments inside a given castle' do
      allow(homesick).to receive('inside').once.with(kind_of(Pathname)).and_yield
      allow(homesick).to receive('say_status').once
              .with(be_a(String),
                    be_a(String),
                    :green)
      allow(homesick).to receive('system').once.with('ls')
      Capture.stdout { homesick.exec 'castle_repo', 'ls' }
    end

    it 'executes a single command with arguments inside a given castle' do
      allow(homesick).to receive('inside').once.with(kind_of(Pathname)).and_yield
      allow(homesick).to receive('say_status').once
              .with(be_a(String),
                    be_a(String),
                    :green)
      allow(homesick).to receive('system').once.with('ls -la')
      Capture.stdout { homesick.exec 'castle_repo', 'ls', '-la' }
    end

    it 'raises an error when the method is called without a command' do
      allow(homesick).to receive('say_status').once
              .with(:error,
                    be_a(String),
                    :red)
      allow(homesick).to receive('exit').once.with(1)
      Capture.stdout { homesick.exec 'castle_repo' }
    end

    context 'pretend' do
      it 'does not execute a command when the pretend option is passed' do
        allow(homesick).to receive('say_status').once
              .with(be_a(String),
                    match(/.*Would execute.*/),
                    :green)
        expect(homesick).to receive('system').never
        Capture.stdout { homesick.invoke 'exec', %w(castle_repo ls -la), pretend: true }
      end
    end

    context 'quiet' do
      it 'does not print status information when quiet is passed' do
        expect(homesick).to receive('say_status').never
        allow(homesick).to receive('system').once
                .with('ls -la')
        Capture.stdout { homesick.invoke 'exec', %w(castle_repo ls -la), quiet: true }
      end
    end
  end

  describe 'exec_all' do
    before do
      given_castle 'castle_repo'
      given_castle 'another_castle_repo'
    end

    it 'executes a command without arguments inside the root of each cloned castle' do
      allow(homesick).to receive('inside_each_castle').exactly(:twice).and_yield('castle_repo').and_yield('another_castle_repo')
      allow(homesick).to receive('say_status').at_least(:once)
              .with(be_a(String),
                    be_a(String),
                    :green)
      allow(homesick).to receive('system').at_least(:once).with('ls')
      Capture.stdout { homesick.exec_all 'ls' }
    end

    it 'executes a command with arguments inside the root of each cloned castle' do
      allow(homesick).to receive('inside_each_castle').exactly(:twice).and_yield('castle_repo').and_yield('another_castle_repo')
      allow(homesick).to receive('say_status').at_least(:once)
              .with(be_a(String),
                    be_a(String),
                    :green)
      allow(homesick).to receive('system').at_least(:once).with('ls -la')
      Capture.stdout { homesick.exec_all 'ls', '-la' }
    end

    it 'raises an error when the method is called without a command' do
      allow(homesick).to receive('say_status').once
              .with(:error,
                    be_a(String),
                    :red)
      allow(homesick).to receive('exit').once.with(1)
      Capture.stdout { homesick.exec_all }
    end

    context 'pretend' do
      it 'does not execute a command when the pretend option is passed' do
        allow(homesick).to receive('say_status').at_least(:once)
              .with(be_a(String),
                    match(/.*Would execute.*/),
                    :green)
        expect(homesick).to receive('system').never
        Capture.stdout { homesick.invoke 'exec_all', %w(ls -la), pretend: true }
      end
    end

    context 'quiet' do
      it 'does not print status information when quiet is passed' do
        expect(homesick).to receive('say_status').never
        allow(homesick).to receive('system').at_least(:once)
                .with('ls -la')
        Capture.stdout { homesick.invoke 'exec_all', %w(ls -la), quiet: true }
      end
    end
  end
end
