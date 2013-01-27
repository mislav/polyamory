require 'polyamory/rooted_pathname'
require 'polyamory/command'

module Polyamory
  # Internal: Deals with finding specs to test
  class RSpec
    attr_reader :context

    def initialize context
      @context = context
    end

    def test_dir_name
      'spec'
    end

    def test_dir
      @test_dir ||= context.root + test_dir_name
    end

    def file_pattern dir
      "#{dir}/**/*_spec.rb"
    end

    # Internal: Finds test files matching glob pattern
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
      if names.any?
        paths = []
        for name in names
          paths.concat Array(resolve_name name)
        end
        paths
      else
        Array(resolve_as_directory test_dir_name)
      end
    end

    def handle? path
      path.in_dir? test_dir
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
      [test_dir + name, context.root + name].detect { |dir|
        dir.directory? and handle? dir
      }
    end

    # "test/unit/test_user.rb:42"
    def resolve_as_filename name
      filename = name.sub(/:(\d+)$/, '')
      file = context.root + filename

      if file.file? and handle? file
        context.root + name
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
      Command.new 'rspec' do |test_job|
        add_ruby_options test_job
        test_job.concat rspec_options
        test_job.concat paths.map {|p| p.relative }
      end
    end

    def glob pattern
      RootedPathname.glob pattern, context.root
    end

    def add_ruby_options cmd
      opts = []
      opts << '-w' if context.warnings?
      opts << '%'
      cmd.env['RUBYOPT'] = opts.join(' ')
    end

    def rspec_options
      opts = []
      opts << '-b' if context.full_backtrace?
      opts << '--seed' << context.test_seed if context.test_seed
      for path in context.load_paths
        opts << "-I#{path}"
      end
      for filter in context.name_filters
        opts << '-e' << filter
      end
      for tag in context.tag_filters
        opts << '-t' << tag
      end
      opts
    end
  end
end
