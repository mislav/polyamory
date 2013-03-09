require 'polyamory/rspec'
require 'polyamory/command'

module Polyamory
  # Internal: Deals with finding specs to test
  class Cucumber < RSpec
    def test_dir_name
      'features'
    end

    def file_pattern dir
      "#{dir}/**/*.feature"
    end

    def test_command paths
      Command.new 'cucumber' do |test_job|
        add_ruby_options test_job
        test_job.concat cucumber_options
        test_job.concat paths.map {|p| p.relative }
      end
    end

    def add_ruby_options cmd
      opts = []
      opts << '-w' if context.warnings?
      for path in context.load_paths
        opts << "-I#{path}"
      end
      opts << '%'
      cmd.env['RUBYOPT'] = opts.join(' ') if opts.size > 1
    end

    def cucumber_options
      opts = []
      opts << '-b' if context.full_backtrace?
      for filter in context.name_filters
        opts << '-n' << filter
      end
      for tag in context.tag_filters
        opts << '-t' << normalize_tag(tag)
      end
      opts
    end

    def normalize_tag tag
      tag = "#$1@#$2" if tag =~ /^(~)?(\w+)$/
      tag
    end
  end
end
