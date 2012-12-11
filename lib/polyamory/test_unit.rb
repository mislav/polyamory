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

    # Internal: Memoized find_files in primary dir
    def all_matching_files
      @all_matching_files ||= find_files
    end

    # Public: Resolve a set of files, directories, and patterns to a list of
    # paths to test.
    def resolve_paths names
      if names.any?
        paths = []
        for name in names
          paths.concat Array(resolve_name name)
        end
        paths
      else
        all_matching_files
      end
    end

    def handle? path
      path.in_dir? test_dir
    end

    def resolve_name name
      filename = name.sub(/:(\d+)$/, '')
      line_number = $1

      resolve_as_directory(name) or
        resolve_as_filename(name) or
        resolve_as_file_pattern(name) or
        raise "nothing resolved from #{name}"
    end

    # "functional" => "test/functional/**"
    # "test/functional" => "test/functional/**"
    def resolve_as_directory name
      dir = [test_dir + name, context.root + name].detect { |dir|
        dir.directory? and handle? dir
      }
      find_files(dir) if dir
    end

    # "test/unit/test_user.rb:42"
    def resolve_as_filename name
      filename = name.sub(/:(\d+)$/, '')
      line_number = $1
      file = context.root + filename

      if file.file? and handle? file
        add_test_filter_for_line(file, line_number) if line_number
        file
      end
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
        [test_command(to_test)]
      else
        []
      end
    end

    def test_command paths
      Command.new %w'polyamory -t' do |test_job|
        add_ruby_options test_job
        test_job.concat paths.map {|p| p.relative }

        tunit_opts = testunit_options
        if tunit_opts.any?
          test_job << '--'
          test_job.concat tunit_opts
        end
      end
    end

    def glob pattern
      RootedPathname.glob pattern, context.root
    end

    def add_ruby_options cmd
      opts = []
      opts << '-w' if context.warnings?
      opts << '-Ilib:test'
      opts << '%'
      cmd.env['RUBYOPT'] = opts.join(' ')
    end

    def testunit_options
      opts = []
      opts << '-n' << test_filter_regexp(test_filters) if test_filters.any?
      opts << '-s' << context.test_seed if context.test_seed
      opts << '-v' if context.verbose?
      opts
    end

    def test_filter_regexp filters
      if filters.size == 1
        '/%s/' % filters.first
      else
        '/(%s)/' % filters.join('|')
      end
    end

    def add_test_filter_for_line file, linenum
      @test_filters << find_test_filter_for_line(file, linenum)
    end

    def find_test_filter_for_line file, linenum
      focused_test_finder.call(file, linenum) or
        raise "test method not found (#{file.relative}:#{linenum})"
    end

    def focused_test_finder() FocusedTestFinder end

    FocusedTestFinder = Struct.new(:file, :line) do
      def self.call *args
        new(*args).scan
      end

      def readlines
        file.readlines[0, line.to_i]
      end

      def scan
        readlines.reverse.each do |line|
          found = test_from_line line
          return found if found
        end
        nil
      end

      def test_from_line line
        case line
        when /^\s*def\s+(test_\w+)/
          $1
        when /^\s*(test|it|specify)[\s(]+(['"])((.*?)[^\\])\2/
          if 'test' == $1 then $3.gsub(/\s+/, '_')  # ActiveSupport::TestCase
          else $3  # minitest/spec
          end
        end
      end
    end
  end
end
