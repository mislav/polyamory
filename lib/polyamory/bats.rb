require 'polyamory/rooted_pathname'
require 'polyamory/command'

module Polyamory
  # Internal: Deals with finding Bats files to test
  # https://github.com/sstephenson/bats#readme
  class Bats
    attr_reader :context

    def initialize context
      @context = context
    end

    def test_dir
      @test_dir ||= context.root + 'test'
    end

    def file_pattern dir
      "#{dir}/*.bats"
    end

    def handle? path
      path.extname == '.bats' || !find_files(path).empty?
    end

    def find_files dir = test_dir
      glob file_pattern(dir)
    end

    # Internal: Memoized find_files in primary dir
    def all_matching_files
      @all_matching_files ||= find_files
    end

    # Public: Resolve a set of files, directories, and patterns to a list of
    # paths to test.
    def resolve_paths names
      if context.tag_filters.any?
        # Bats doesn't support tags
        []
      elsif names.any?
        paths = []
        for name in names
          paths.concat Array(resolve_name name)
        end
        paths
      else
        [test_dir]
      end
    end

    def resolve_name name
      resolve_as_directory(name) or
        resolve_as_filename(name) or
        resolve_as_file_pattern(name) or
        raise "nothing resolved from #{name}"
    end

    # "functional" => "test/functional/**"
    # "test/functional" => "test/functional/**"
    def resolve_as_directory name
      [test_dir + name, context.root + name].detect { |dir| handle?(dir) }
    end

    # "test/unit/hello.bats"
    def resolve_as_filename name
      file = context.root + name
      file if file.file? and handle?(file)
    end

    # "word" => "test/**" that match "word"
    def resolve_as_file_pattern name
      pattern = /(?:\b|_)#{Regexp.escape name}(?:\b|_)/
      all_matching_files.select {|p| p =~ pattern }
    end

    # Public: From a list of paths, yank the ones that this knows how to handle,
    # and build test jobs from it.
    def pick_jobs paths
      to_test = []
      paths.reject! do |path|
        if handle? path
          to_test << path
          true
        end
      end

      unless to_test.empty?
        excess = to_test.slice!(1..-1)
        warn "warning: bats can only accept one filename; skipping #{excess.map {|p| p.relative }.join(' ')}" unless excess.empty?
        [test_command(to_test)]
      else
        []
      end
    end

    def test_command paths
      Command.new ['bats'] do |test_job|
        test_job.concat paths.map {|p| p.relative }
      end
    end

    def glob pattern
      RootedPathname.glob pattern, context.root
    end
  end
end
