require 'pathname'

class Polyamory
  def self.run(*args)
    new(*args).run
  end
  
  def initialize(names, root, options = {})
    @names = names
    @root = Pathname.new(root).expand_path
    @options = options
  end
  
  def noop?
    @options[:noop]
  end
  
  def file_exists?(path)
    (@root + path).exist?
  end
  
  def bundler?
    file_exists? 'Gemfile'
  end
  
  def test_dir
    @root + 'test'
  end
  
  def test_glob(dir = test_dir)
    "#{dir}/**/*_test.rb"
  end
  
  def test_glob_alt(dir = test_dir)
    "#{dir}/**/test*.rb"
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
  
  class Pathname < Pathname
    attr_reader :root
    
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
    
    def relative
      return self if relative?
      @relativized ||= relative_path_from root
    end
    
    def =~(pattern)
      relative.to_s =~ pattern
    end
    
    def +(other)
      result = self.class.new(plus(@path, other.to_s))
      result.root ||= self
      result
    end
  end

  def find_test_files(dir = test_dir)
    test_paths = Pathname.glob(test_glob(dir), @root)
    test_paths_alt = Pathname.glob(test_glob_alt(dir), @root)
    test_paths.size > test_paths_alt.size ? test_paths : test_paths_alt
  end

  def find_files
    all_paths = Pathname.glob([spec_glob, features_glob].flatten, @root)
    all_paths.concat find_test_files

    if @names.any?
      @names.map { |name|
        path = @root + name
        pattern = /(\b|_)#{Regexp.escape name}(\b|_)/
        
        if path.directory? or not path.extname.empty?
          path
        else
          all_paths.select { |p| p =~ pattern }
        end
      }.flatten
    else
      [test_dir, spec_dir, features_dir].select { |p| p.directory? }
    end
  end
  
  def relativize(paths)
    Array(paths).map { |p| p.relative }
  end
  
  def run
    paths = relativize(find_files)
    if paths.empty?
      warn "nothing found to run"
      exit 1
    end
    
    jobs = index_by_path_prefix(paths).map do |prefix, files|
      [runner_for_prefix(prefix), *files].flatten
    end

    execute_jobs jobs
  end
  
  def runner_for_prefix(prefix)
    case prefix
    when 'features' then %w[cucumber -f progress -t ~@wip]
    when 'spec' then detect_rspec_version
    when 'test' then %w[polyamory -t]
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
  
  def index_by_path_prefix(paths)
    paths.inject(Hash.new {|h,k| h[k] = [] }) do |index, path|
      prefix = path.to_s.split('/', 2).first
      index[prefix] << path
      index
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
