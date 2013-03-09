require 'formula'

class Polyamory < Formula
  homepage 'https://github.com/mislav/polyamory#readme'
  url      'https://github.com/mislav/polyamory/tarball/v0.6.2'
  sha1     'c4d63cc22b58d89a8cbea1cd22870d1f1bfe8ac3'
  head     'https://github.com/mislav/polyamory.git'

  def install
    inreplace 'bin/polyamory', '/usr/bin/env ruby',
      "/usr/bin/ruby\n$LOAD_PATH.unshift '#{prefix}/lib'"

    prefix.install 'lib'
    bin.install 'bin/polyamory'
  end
end
