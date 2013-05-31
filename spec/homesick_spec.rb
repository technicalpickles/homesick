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

    context "when symlink to directory exists" do
      it "asks if it should remove symlink" do
        homesick.shell = double()
        homesick.shell.should_receive(:file_collision) { false }

        somewhere_else = create_construct.directory(".vim")
        existing_dotdir_link = home.join(".vim")
        FileUtils.ln_s somewhere_else, existing_dotdir_link

        dotfile = castle.directory(".vim").file(".some_dotfile")

        homesick.symlink("glencairn")

        existing_dotdir_link.should be_symlink
        existing_dotdir_link.join(".some_dotfile").readlink.should == dotfile
      end

      it "detects identical files" do
        homesick.shell.stub(:file_collision) { false }
        symlinked_dir = castle.directory(".vim")
        existing_dotdir_link = home.join(".vim")
        FileUtils.ln_s symlinked_dir, existing_dotdir_link

        dotfile = symlinked_dir.file(".some_dotfile")

        homesick.symlink("glencairn")

        existing_dotdir_link.readlink.should == symlinked_dir
        existing_dotdir_link.join(".some_dotfile").realpath.should == dotfile.realpath
      end
    end

    context "when same directory exists in multiple castles" do
      let(:other_castle) { given_castle("other") }

      it "will merge directories" do
        dotfile = castle.directory(".vim").file(".castle")
        other_file = other_castle.directory(".vim").file(".other_castle")

        homesick.symlink("glencairn")
        homesick.symlink("other")

        home.join(".vim", ".castle").readlink.should == dotfile
        home.join(".vim", ".other_castle").readlink.should == other_file
      end
    end

    context "when directory listed in .manifest" do
      let(:manifest) { castle.join(Homesick::MANIFEST_FILENAME) }
      it "will symlink the directory instead of it's children" do
        dotdir = castle.directory(".vim")
        dotfile = dotdir.file(".file")
        manifest.open('w+') { |f| f.puts ".vim" }

        homesick.symlink("glencairn")

        home.join(".vim").should be_symlink
        home.join(".vim").readlink.should == dotdir
        home.join(".vim", ".file").should_not be_symlink
      end
    end

    context "when forced" do
      let(:homesick) { Homesick.new [], :force => true }

      context "when symlink to directory exists" do
        it "does remove symlink" do
            somewhere_else = create_construct.directory(".vim")
            existing_dotdir_link = home.join(".vim")
            FileUtils.ln_s somewhere_else, existing_dotdir_link

            dotfile = castle.directory(".vim").file(".some_dotfile")

            homesick.symlink("glencairn")

            existing_dotdir_link.should_not be_symlink
            existing_dotdir_link.join(".some_dotfile").readlink.should == dotfile
        end
      end

      it "can override symlinks to files" do
        somewhere_else = create_construct.file(".vim")
        existing_dotfile_link = home.join(".vim")
        FileUtils.ln_s somewhere_else, existing_dotfile_link

        dotfile = castle.file(".vim")

        homesick.symlink("glencairn")

        existing_dotfile_link.readlink.should == dotfile
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

  describe "commit" do

    xit "needs testing"

  end

  describe "push" do

    xit "needs testing"

  end

  describe "track" do
    let(:castle) { given_castle("castle_repo") }

    context "file" do
      it "should move the file into the castle" do
        some_rc_file = home.file(".some_rc_file")
        tracked_file = castle.join(".some_rc_file")

        homesick.track(some_rc_file, "castle_repo")

        tracked_file.should exist
        some_rc_file.readlink.should == tracked_file
      end

      it "should move the file in a nested folder structure into similar structure" do
        some_nested_file = home.file("some/nested/file.txt")
        tracked_file = castle.join("some/nested/file.txt")

        homesick.track(some_nested_file, "castle_repo")

        tracked_file.should exist
        some_nested_file.readlink.should == tracked_file
      end

      context ".manifest" do
        before(:each) do
          castle
        end
        let(:manifest) { castle.join(Homesick::MANIFEST_FILENAME) }

        it "should not add file to manifest" do
          path = ".some_file"
          some_file = home.file(path)

          homesick.track(some_file, "castle_repo")

          manifest.should_not exist
        end

      end
    end

    context "directory" do
      context "should move the directory into the castle" do
        it "without trailing slash" do
          some_dir = home.directory(".some_dir")
          tracked_dir = castle.join(".some_dir")

          homesick.track(some_dir, "castle_repo")

          tracked_dir.should exist
          some_dir.readlink.should == tracked_dir
        end

        it "with trailing slash" do
          some_dir = home.directory(".some_dir/")
          tracked_dir = castle.join(".some_dir")

          homesick.track(some_dir, "castle_repo")

          tracked_dir.should exist
          home.join('.some_dir').readlink.should == tracked_dir
        end
      end

      it "should move a nested directory" do
        some_nested_dir = home.directory("some/nested/directory")
        tracked_dir = castle.join("some/nested/directory")

        homesick.track(some_nested_dir, "castle_repo")

        some_nested_dir.should exist
        some_nested_dir.readlink.should == tracked_dir
      end

      context ".manifest" do
        before(:each) do
          castle
        end
        let(:manifest) { castle.join(Homesick::MANIFEST_FILENAME) }

        it "should add directory to manifest" do
          path = ".some_dir"
          some_dir = home.directory(path)

          homesick.track(some_dir, "castle_repo")

          manifest.open.read.should == "#{path}\n"
        end

        it "should add nested directory to manifest" do
          path = "some/nested/directory"
          some_nested_dir = home.directory(path)

          homesick.track(some_nested_dir, "castle_repo")

          manifest.open.read.should == "#{path}\n"
        end

        it "should not add nested directory if parent is already listed" do
          parent_path = "parent"
          parent_dir = home.directory(parent_path)
          some_nested_dir = parent_dir.directory("directory")

          homesick.track(parent_dir, "castle_repo")
          homesick.track(some_nested_dir, "castle_repo")

          manifest.open.read.should == "#{parent_path}\n"
        end

        it "should remove nested directory if parent is tracked" do
          parent_path = "parent"
          parent_dir = home.directory(parent_path)
          some_nested_dir = parent_dir.directory("directory")

          homesick.track(some_nested_dir, "castle_repo")
          homesick.track(parent_dir, "castle_repo")

          manifest.open.read.should == "#{parent_path}\n"
        end
      end
    end
  end
end
