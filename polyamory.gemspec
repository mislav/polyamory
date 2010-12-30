# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name    = 'polyamory'
  gem.version = '0.0.2'
  gem.date    = Time.now.strftime('%Y-%m-%d')

  # gem.add_dependency 'hpricot', '~> 0.8.2'
  # gem.add_development_dependency 'rspec', '~> 1.2.9'

  gem.summary = "Runs your tests"
  gem.description = "A tool that knows how to run your tests regardless of framework"

  gem.authors  = ['Mislav Marohnić']
  gem.email    = 'mislav.marohnic@gmail.com'
  gem.homepage = 'http://github.com/mislav/polyamory'

  gem.rubyforge_project = nil
  gem.has_rdoc = false
  # gem.rdoc_options = ['--main', 'README.rdoc', '--charset=UTF-8']
  # gem.extra_rdoc_files = ['README.rdoc', 'LICENSE', 'CHANGELOG.rdoc']

  gem.executables = %w( polyamory )
  gem.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end
