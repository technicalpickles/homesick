require 'spec_helper'

describe 'clone' do
  let(:home) { create_construct }
  after { home.destroy! }

  let(:castles) { home.directory('.homesick/repos') }

  let(:homesick) { Homesick::Commands::Clone.new }

  before do
    homesick.stub(:repos_dir).and_return(castles)
    homesick.stub(:rc)
  end

  context 'has a .homesickrc' do
    it 'should run the .homesickrc' do
      somewhere = create_construct
      local_repo = somewhere.directory('some_repo')

      homesick.should_receive(:rc).with(Pathname.new('some_repo'))
      homesick.clone local_repo
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
    homesick.should_receive(:git_clone).with('https://github.com/wfarr/dotfiles.git', :destination => Pathname.new('wfarr/dotfiles'))

    homesick.clone 'wfarr/dotfiles'
  end
end


