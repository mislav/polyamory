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

  gem.summary = "The promiscuous test runner"
  gem.description = "A cli runner for all tests regardless of framework"

  gem.authors  = ['Mislav Marohnić']
  gem.email    = 'mislav.marohnic@gmail.com'
  gem.homepage = 'https://github.com/mislav/polyamory#readme'

  gem.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*']

  dev_null  = File.exist?('/dev/null') ? '/dev/null' : 'NUL'
  git_files = `git ls-files -z 2>#{dev_null}`
  gem.files &= git_files.split("\0") if $?.success?
end
