# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name    = 'polyamory'
  gem.version = '0.0.5'

  gem.executables = %w( polyamory )

  gem.summary = "Runs your tests"
  gem.description = "A tool that knows how to run your tests regardless of framework"

  gem.authors  = ['Mislav Marohnić']
  gem.email    = 'mislav.marohnic@gmail.com'
  gem.homepage = 'https://github.com/mislav/polyamory'

  gem.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end
