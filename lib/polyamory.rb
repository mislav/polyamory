require 'optparse'
require 'polyamory/runner'

module Polyamory
  def self.run(args, dir)
    options = parse_options! args
    Runner.new(args, dir, options).run
  end

  def self.parse_options!(args)
    options = {}
    OptionParser.new do |opts|
      opts.banner  = 'polyamory options:'
      opts.version = '0.0'

      opts.on '-h', '--help', 'Display this help' do
        puts opts
        exit
      end

      opts.on '-s', '--seed SEED', Integer, "Set random seed" do |m|
        options[:test_seed] = m.to_i
      end

      opts.on '-n', '--name PATTERN', "Filter test names on pattern" do |str|
        options[:test_filter] = str
      end

      opts.on '-w', "Turn on Ruby warnings" do
        options[:warnings] = true
      end

      opts.on '-v', '--verbose', "Show progress processing files" do
        options[:verbose] = true
      end

      opts.parse! args
    end
    options
  end
end

__END__

  def bundler?
    file_exists? 'Gemfile'
  end

  def spec_dir
    @root + 'spec'
  end

  def spec_glob(dir = spec_dir)
    "#{dir}/**/*_spec.rb"
  end

  def features_dir
    @root + 'features'
  end

  def features_glob(dir = features_dir)
    "#{dir}/**/*.feature"
  end

  def runner_for_prefix(prefix)
    case prefix
    when 'features' then %w[cucumber -f progress -t ~@wip]
    when 'spec' then detect_rspec_version
    else
      raise ArgumentError, "don't know a runner for #{prefix}"
    end
  end

  def detect_rspec_version
    helper = 'spec/spec_helper.rb'

    if file_exists? 'spec/spec.opts' or file_exists? 'lib/tasks/rspec.rake'
      'spec'
    elsif file_exists? '.rspec'
      'rspec'
    elsif file_exists? helper
      File.open(helper) do |file|
        while file.gets
          return $&.downcase if $_ =~ /\bR?Spec\b/
        end
      end
      'rspec'
    else
      'rspec'
    end
  end

  def execute_jobs(jobs)
    if jobs.size > 1
      jobs.each { |j| cmd(j, true) }
    else
      cmd(jobs.first)
    end
  end

  def prepare_cmdline(args)
    args = args.map { |p| p.to_s }
    args = %w[bundle exec] + args if bundler?
    args
  end

  def cmd(args, many = false)
    args = prepare_cmdline(args)
    puts args.join(' ')

    unless noop?
      # TODO: hack; make this configurable, use bundler
      with_rubyopt(!bundler? ? '-rubygems' : nil) do
        with_rubylib('lib', args.include?('polyamory') ? 'test' : nil) do
          if many
            system(*args)
            exit $?.exitstatus unless $?.success?
          else
            exec(*args)
          end
        end
      end
    end
  end

  def with_rubyopt(value)
    with_env('RUBYOPT', "#{value} %s") { yield }
  end

  def with_rubylib(*values)
    value = values.flatten.compact.join(':')
    with_env('RUBYLIB', "#{value}:%s") { yield }
  end

  def with_env(key, value)
    old_value = ENV[key]
    ENV[key] = value % old_value

    begin
      yield
    ensure
      ENV[key] = old_value
    end
  end
end
