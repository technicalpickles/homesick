$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'homesick'
require 'rspec'
require 'rspec/autorun'
require 'construct'

RSpec.configure do |config|
  config.include Construct::Helpers

  config.before do
    @user_dir = create_construct
    ENV['HOME'] = @user_dir.to_s

    @repos_dir = @user_dir.directory(".homesick/repos")
    homesick.stub!(:repos_dir).and_return(@repos_dir)
  end

  config.after do
    @user_dir.destroy!
  end

  def given_castle(name, path=name)
    @repos_dir.directory(path) do |castle|
      Dir.chdir(castle) do
        system "git init >/dev/null 2>&1"
        system "git remote add origin git://github.com/technicalpickles/#{name}.git >/dev/null 2>&1"
        return castle.directory("home")
      end
    end
  end
end
