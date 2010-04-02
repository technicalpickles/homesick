$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'homesick'
require 'spec'
require 'spec/autorun'
require 'construct'

Spec::Runner.configure do |config|
  config.include Construct::Helpers

  config.before do
    @user_dir = create_construct
    ENV['HOME'] = @user_dir.to_s
  end

  config.after do
    @user_dir.destroy!
  end
end
