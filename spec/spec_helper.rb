$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'homesick'
require 'rspec'
require 'rspec/autorun'
require 'construct'

RSpec.configure do |config|
  config.include Construct::Helpers

  config.before { ENV['HOME'] = home.to_s }

  config.before { silence! }

  def silence!
    homesick.stub(:say_status)
  end

  def given_castle(name, path=name)
    castles.directory(path) do |castle|
      Dir.chdir(castle) do
        system "git init >/dev/null 2>&1"
        system "git remote add origin git://github.com/technicalpickles/#{name}.git >/dev/null 2>&1"
        return castle.directory("home")
      end
    end
  end
end
