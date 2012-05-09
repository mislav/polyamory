require 'polyamory/rooted_pathname'
require 'polyamory/command'

module Polyamory
  # Internal: Deals with finding Test::Unit or MiniTest files to test.
  class TestUnit
    attr_reader :context, :test_filters

    def initialize context
      @context = context
      @test_filters = Array(context.test_filter)
    end

    def test_dir
      @test_dir ||= context.root + 'test'
    end

    def file_pattern dir
      "#{dir}/**/*_test.rb"
    end

    def file_pattern_alt dir
      "#{dir}/**/test*.rb"
    end

    # Internal: Finds test files with one glob pattern or the other. The pattern
    # that matches the most files wins.
    def find_files dir = test_dir
      paths = glob file_pattern(dir)
      paths_alt = glob file_pattern_alt(dir)
      paths.size > paths_alt.size ? paths : paths_alt
    end

    # Public: Resolve a set of files, directories, and patterns to a list of
    # paths to test.
    def resolve_paths names
      if names.any?
        all_files = nil
        names.inject([]) do |paths, name|
          filename = name.sub(/:(\d+)$/, '')
          line_number = $1

          if (dir = test_dir + name).directory?
            # "functional" => "test/functional/**"
            paths.concat find_files(dir)
          elsif (file = context.root + filename).file? and handle? file
            # "test/unit/test_user.rb:42"
            add_test_filter_for_line(file, line_number) if line_number
            paths << file
          elsif (dir = context.root + name).directory? and handle? dir
            # "test/functional" => "test/functional/**"
            paths.concat find_files(dir)
          else
            # "word" => "test/**" that match "word"
            pattern = /(?:\b|_)#{Regexp.escape name}(?:\b|_)/
            all_files ||= find_files
            paths.concat all_files.select {|p| p =~ pattern }
          end

          paths
        end
      else
        find_files
      end
    end

    def handle? path
      path.in_dir? test_dir
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
        [test_command(to_test)]
      else
        []
      end
    end

    def test_command paths
      Command.new 'ruby' do |test_job|
        test_job.concat ruby_options
        test_job << '-S' << 'testrb'
        test_job.concat testunit_options
        test_job.concat paths.map {|p| p.relative }
      end
    end

    def glob pattern
      RootedPathname.glob pattern, context.root
    end

    def ruby_options
      opts = []
      opts << '-w' if context.warnings?
      opts << '-Ilib:test'
      opts
    end

    def testunit_options
      opts = []
      if test_filters.any?
        opts << '-n'
        if test_filters.size == 1
          opts << '/%s/' % test_filters.first
        else
          opts << '/(%s)/' % test_filters.join('|')
        end
      end
      opts << '-s' << context.test_seed if context.test_seed
      opts << '-v' if context.verbose?
      opts
    end

    def add_test_filter_for_line file, linenum
      @test_filters << find_test_filter_for_line(file, linenum)
    end

    def find_test_filter_for_line file, linenum
      lines = file.readlines[0, linenum.to_i].reverse
      lines.each do |line|
        case line
        when /^\s*def\s+(test_\w+)/
          return $1
        when /^\s*(test|it|specify)[\s(]+(['"])((.*?)[^\\])\2/
          return ('test' == $1) ?
            $3.gsub(/\s+/, '_') : # ActiveSupport::TestCase
            $3.gsub(/\W+/u, '_')  # minitest/spec
        end
      end

      raise "test method not found (#{file.relative}:#{linenum})"
    end
  end
end
