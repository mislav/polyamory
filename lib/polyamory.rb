require 'pathname'

class Polyamory
  def self.run(*args)
    new(*args).run
  end
  
  def initialize(names, root, options = {})
    @names = names
    @root = ::Pathname.new(root).expand_path
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
      @relativized ||= relative_path_from root
    end
    
    def =~(pattern)
      relative.to_s =~ pattern
    end
  end
  
  def find_files
    all_paths = Pathname.glob([test_glob, spec_glob, features_glob], @root)
    
    if @names.any?
      @names.map { |name|
        path = @root + name
        pattern = /\b#{Regexp.escape name}(\b|_)/
        
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
    
    prepare_env
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
    if file_exists? 'spec/spec.opts' or
        file_exists? 'lib/tasks/rspec.rake'
      'spec'
    elsif file_exists? '.rspec'
      'rspec'
    elsif helper = 'spec/spec_helper.rb' and helper.exist?
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
    args = %w[bundle exec] + args if args.first != 'polyamory' and bundler?
    args
  end
  
  def cmd(args, many = false)
    args = prepare_cmdline(args)
    puts args.join(' ')

    # TODO: hack; make this configurable, use bundler
    with_rubyopt(args.first == 'polyamory' ? '-rubygems' : nil) do
      if many
        system(*args)
      else
        exec(*args)
      end
    end unless noop?
  end
  
  def with_rubyopt(value)
    old_value = ENV['RUBYOPT']
    ENV['RUBYOPT'] = "#{value} #{old_value}"
    
    begin
      yield
    ensure
      ENV['RUBYOPT'] = old_value
    end
  end
  
  def prepare_env
    # TODO: make this per-job
    ENV['RUBYOPT'] = ENV['RUBYOPT'].gsub(/(^| )-w( |$)/, '\1\2') if ENV['RUBYOPT']
  end
end