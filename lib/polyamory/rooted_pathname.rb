require 'pathname'

module Polyamory
  # A kind of Pathname that keeps a reference to a root directory and is able to
  # return a relativized pathname from that particular root.
  class RootedPathname < ::Pathname
    attr_reader :root

    # Find pathnames matching the glob pattern and assign to them a root
    def self.glob(patterns, root)
      patterns = Array(patterns)
      Dir[*patterns].map do |path|
        self.new(path, root)
      end
    end

    def initialize(path, root_path = nil)
      super(path)
      self.root = root_path
    end

    def root=(path)
      @relativized = nil
      @root = path
    end

    # Return the relative portion of the path from root
    def relative
      return self if relative?
      @relativized ||= relative_path_from root
    end

    # Check if current path is contained in directory
    def in_dir? dir
      self == dir or
        self.to_s.index(File.join(dir, '')) == 0
    end

    # Perform a regex match only on the relative portion of the path
    def =~(pattern)
      relative.to_s =~ pattern
    end

    # Add to the current path; the result has the current path as root
    def +(other)
      result = self.class.new(plus(@path, other.to_s))
      result.root ||= self
      result
    end
  end
end
