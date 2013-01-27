# encoding: utf-8
version = nil
File.open(File.expand_path('../lib/polyamory.rb', __FILE__)) do |file|
  file.each_line do |line|
    if line =~ /\bVERSION = ['"](.+?)['"]/
      version = $1
      break
    end
  end
end

Gem::Specification.new do |gem|
  gem.name    = 'polyamory'
  gem.version = version

  gem.executables = %w( polyamory )

  gem.summary = "Runs your tests"
  gem.description = "A tool that knows how to run your tests regardless of framework"

  gem.authors  = ['Mislav Marohnić']
  gem.email    = 'mislav.marohnic@gmail.com'
  gem.homepage = 'https://github.com/mislav/polyamory'

  gem.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end
