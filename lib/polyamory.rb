require 'optparse'
require 'polyamory/runner'

module Polyamory
  VERSION = '0.6.0'

  def self.run(args, dir)
    options = parse_options! args
    Runner.new(args, dir, options).run
  end

  def self.parse_options!(args)
    options = {
      :warnings     => false,
      :verbose      => false,
      :backtrace    => false,
      :test_seed    => nil,
      :name_filters => [],
      :tag_filters  => [],
      :load_paths   => [],
    }

    OptionParser.new do |opts|
      opts.banner  = 'polyamory options:'
      opts.version = VERSION

      opts.on '-h', '--help', 'Display this help' do
        puts opts
        exit
      end

      opts.on '-s', '--seed SEED', Integer, "Set random seed" do |m|
        options[:test_seed] = m.to_i
      end

      opts.on '-n', '--name PATTERN', "Filter test names on pattern" do |str|
        options[:name_filters] << str
      end

      opts.on '-t', '--tag TAG', "Filter tests on tag" do |str|
        options[:tag_filters] << str
      end

      opts.on '-b', '--backtrace', "Show full backtrace" do |str|
        options[:backtrace] = true
      end

      opts.on '-I PATH', "Directory to load on $LOAD_PATH" do |str|
        options[:load_paths] << str
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
