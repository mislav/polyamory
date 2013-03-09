require 'polyamory/rooted_pathname'
require 'polyamory/test_unit'
require 'polyamory/rspec'
require 'polyamory/cucumber'
require 'polyamory/bats'

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

    def bundle_exec?
      return @bundle_exec if defined? @bundle_exec
      if (setting = options.fetch(:bundler)).nil?
        setting = ENV['RUBYOPT'] !~ /\br?bundler\/setup\b/ &&
          ( !ENV['BUNDLE_GEMFILE'].to_s.empty? || (root + 'Gemfile').exist? )
      end
      @bundle_exec = setting
    end

    BundlerJob = Struct.new(:job) do
      def env() job.env end
      def to_exec() ['bundle', 'exec', *job.to_exec] end
      def to_s() "bundle exec #{job.to_s}" end
    end

    def run
      jobs = collect_jobs

      unless jobs.empty?
        for job in jobs
          job = BundlerJob.new(job) if bundle_exec?
          exec_job job
        end
      else
        abort "nothing to run."
      end
    end

    def collect_jobs
      [TestUnit, RSpec, Cucumber, Bats].inject([]) do |jobs, klass|
        framework = klass.new self
        paths = framework.resolve_paths @names
        jobs.concat framework.pick_jobs(paths)
      end
    end

    def exec_job job
      with_env job.env do |env_keys|
        display_job job, env_keys
        system(*job.to_exec)
        exit $?.exitstatus unless $?.success?
      end
    end

    def display_job job, env_keys
      display_env env_keys
      puts job
    end

    def display_env env_keys
      env_keys.each do |name|
        value = ENV[name].strip
        next if value.empty?
        value = %("#{value}") if value.index(' ')
        print "#{name}=#{value} "
      end
    end

    def rbenv_clear
      rbenv_root = `rbenv root 2>/dev/null`.chomp
      unless rbenv_root.empty?
        re = /^#{Regexp.escape rbenv_root}\/(versions|plugins|libexec)\b/
        paths = ENV["PATH"].split(":")
        paths.reject! {|p| p =~ re }
        update_env 'PATH' => paths.join(":")
      end
    end

    def with_env env
      rbenv_clear
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
