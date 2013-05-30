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

  def given_castle(path, subdirs=[])
    name = Pathname.new(path).basename
    castles.directory(path) do |castle|
      Dir.chdir(castle) do
        system "git init >/dev/null 2>&1"
        system "git remote add origin git://github.com/technicalpickles/#{name}.git >/dev/null 2>&1"
        castle_home = castle.directory("home")
        if subdirs then
          subdir_file = castle_home.join(Homesick::SUBDIR_FILENAME)
          subdirs.each do |subdir|
            system "echo #{subdir} >> #{subdir_file}"
          end
        end
        return castle_home
      end
    end
  end
end
