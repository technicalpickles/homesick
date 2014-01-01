guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/homesick/.*\.rb}) { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }

  notification :tmux, display_message: true
end

