require 'pathname'
require 'polyamory/test_unit'
require 'polyamory/rooted_pathname'

module Polyamory
  # Public: Collects test jobs in the root directory and runs them.
  class Runner
    attr_reader :root, :options

    def initialize(names, root, options = {})
      @names   = names
      @root    = RootedPathname.new(root).expand_path
      @options = options
    end

    def warnings?
      options.fetch(:warnings, false)
    end

    def verbose?
      options.fetch(:verbose, false)
    end

    def test_filter
      options[:test_filter]
    end

    def test_seed
      options[:test_seed]
    end

    def run
      jobs = collect_jobs

      unless jobs.empty?
        puts jobs
        exec(*jobs.first.to_exec)
      else
        abort "nothing to run."
      end
    end

    def collect_jobs
      unit = TestUnit.new self
      paths = unit.resolve_paths @names
      unit.pick_jobs paths
    end
  end
end
