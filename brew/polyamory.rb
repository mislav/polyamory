require 'formula'

class Polyamory < Formula
  homepage 'https://github.com/mislav/polyamory#readme'
  url      'https://github.com/mislav/polyamory/tarball/v0.6.0'
  sha1     'c025cc220a553208930450fc8cfc78a6157d15d3'
  head     'https://github.com/mislav/polyamory.git'

  def install
    inreplace 'bin/polyamory', '/usr/bin/env ruby',
      "/usr/bin/ruby\n$LOAD_PATH.unshift '#{prefix}/lib'"

    prefix.install 'lib'
    bin.install 'bin/polyamory'
  end
end
