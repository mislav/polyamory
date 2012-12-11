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
        for job in jobs
          exec_job job
        end
      else
        abort "nothing to run."
      end
    end

    def exec_job job
      update_env job.env do |env_keys|
        env_keys.each do |name|
          value = ENV[name].strip
          value = %("#{value}") if value.index(' ')
          print "#{name}=#{value} "
        end
        puts job
        exec(*job.to_exec)
      end
    end

    def update_env env
      saved = {}
      env.each { |name, value|
        saved[name] = ENV[name]
        ENV[name] = value.sub('%', saved[name].to_s)
      }
      begin
        yield saved.keys
      rescue
        saved.each {|name, value| ENV[name] = value }
      end
    end

    def collect_jobs
      unit = TestUnit.new self
      paths = unit.resolve_paths @names
      unit.pick_jobs paths
    end
  end
end
