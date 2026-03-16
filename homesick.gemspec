require_relative 'lib/homesick/version'

Gem::Specification.new do |s|
  s.name        = 'homesick'
  s.version     = Homesick::Version::STRING
  s.summary     = "Your home directory is your castle. Don't leave your dotfiles behind."
  s.description = <<~DESC
    Homesick is sorta like rip, but for dotfiles. It uses git to clone a
    repository containing dotfiles, and saves them in ~/.homesick. It then
    allows you to symlink all the dotfiles into place with a single command.
  DESC
  s.authors     = ['Joshua Nichols', 'Yusuke Murata']
  s.email       = ['josh@technicalpickles.com', 'info@muratayusuke.com']
  s.homepage    = 'https://github.com/technicalpickles/homesick'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.1'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  s.executables   = ['homesick']
  s.require_paths = ['lib']

  s.extra_rdoc_files = %w[ChangeLog.markdown LICENSE README.markdown]

  s.add_dependency 'thor', '~> 1.3'
end
