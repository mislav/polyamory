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
      options.fetch(:warnings)
    end

    def verbose?
      options.fetch(:verbose)
    end

    def full_backtrace?
      options.fetch(:backtrace)
    end

    def name_filters
      options.fetch(:name_filters)
    end

    def tag_filters
      options.fetch(:tag_filters)
    end

    def load_paths
      options.fetch(:load_paths)
    end

    def test_seed
      options.fetch(:test_seed)
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

    def collect_jobs
      unit = TestUnit.new self
      paths = unit.resolve_paths @names
      unit.pick_jobs paths
    end

    def exec_job job
      with_env job.env do |env_keys|
        display_job job, env_keys
        exec(*job.to_exec)
      end
    end

    def display_job job, env_keys
      display_env env_keys
      puts job
    end

    def display_env env_keys
      env_keys.each do |name|
        value = ENV[name].strip
        value = %("#{value}") if value.index(' ')
        print "#{name}=#{value} "
      end
    end

    def with_env env
      saved = update_env env
      begin
        yield saved.keys
      ensure
        restore_env saved
      end
    end

    def update_env env
      env.inject({}) { |saved, (name, value)|
        saved[name] = ENV[name]
        ENV[name] = value.sub('%', saved[name].to_s)
        saved
      }
    end

    def restore_env env
      env.each {|name, value| ENV[name] = value }
    end
  end
end
