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
      :backtrace    => nil,
      :test_seed    => nil,
      :bundler      => nil,
      :name_filters => [],
      :tag_filters  => [],
      :load_paths   => [],
    }

    OptionParser.new do |opts|
      opts.banner  = 'Usage: polyamory [<dirname>] [<file>[:<line>]] [-n <pattern>] [-t <tag>]'
      opts.version = VERSION

      opts.summary_indent = " " * 4

      opts.separator "\n  Ruby options:"

      opts.on '-w', "Turn on Ruby warnings" do
        options[:warnings] = true
      end

      opts.on '-I PATH', "Directory to load on $LOAD_PATH" do |str|
        options[:load_paths] << str
      end

      opts.separator "\n  Test options:"

      opts.on '-s', '--seed SEED', Integer, "Set random seed" do |m|
        options[:test_seed] = m.to_i
      end

      opts.on '-b', '--[no-]backtrace', "Show full backtrace" do |set|
        options[:backtrace] = set
      end

      opts.on '-n', '--name PATTERN', "Filter test names on pattern" do |str|
        options[:name_filters] << str
      end

      opts.on '-t', '--tag TAG', "Filter tests on tag" do |str|
        options[:tag_filters] << str
      end

      opts.on '-v', '--verbose', "Show progress processing files" do
        options[:verbose] = true
      end

      opts.on '--[no-]bundler', "Use `bundle exec' for running tests" do |set|
        options[:bundler] = set
      end

      opts.separator "\n  Other options:"

      opts.on_tail '-h', '--help', 'Display this help' do
        puts opts
        exit
      end

      begin
        opts.parse! args
      rescue OptionParser::InvalidOption
        abort opts.banner
      end
    end

    options
  end
end
