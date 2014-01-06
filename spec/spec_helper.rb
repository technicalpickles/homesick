$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'homesick'
require 'construct'

RSpec.configure do |config|
  config.include Construct::Helpers

  config.before { ENV['HOME'] = home.to_s }

  config.before { silence! }

  def silence!
    homesick.stub(:say_status)
  end

  def given_castle(path, subdirs = [])
    name = Pathname.new(path).basename
    castles.directory(path) do |castle|
      Dir.chdir(castle) do
        system 'git init >/dev/null 2>&1'
        system 'git config user.email "test@test.com"'
        system 'git config user.name "Test Name"'
        system "git remote add origin git://github.com/technicalpickles/#{name}.git >/dev/null 2>&1"
        if subdirs
          subdir_file = castle.join(Homesick::SUBDIR_FILENAME)
          subdirs.each do |subdir|
            system "echo #{subdir} >> #{subdir_file}"
          end
        end
        return castle.directory('home')
      end
    end
  end
end
