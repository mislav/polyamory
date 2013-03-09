require 'minitest/autorun'
require 'minitest/pride'
require 'polyamory/runner'
require 'fileutils'

describe Polyamory::Runner do

  let(:default_options) {
    options = {
      :warnings     => false,
      :verbose      => false,
      :backtrace    => false,
      :test_seed    => nil,
      :name_filters => [],
      :tag_filters  => [],
      :load_paths   => [],
    }
  }
  subject { Polyamory::Runner.new(names, root, default_options.merge(options)) }

  let(:options) { Hash.new }
  let(:names)   { [] }
  let(:root)    { File.join(ENV['TMPDIR'] || '/tmp', 'polyamory') }

  before { FileUtils.rm_rf root }

  it "finds no jobs when directory doesn't exist" do
    subject.collect_jobs.must_be_empty
  end

  describe "test/unit project" do
    before {
      %w[ app/models/user.rb
          lib/sync.rb
          test/unit/user_test.rb
          test/unit/blog_test.rb
          test/functional/lib_user_test.rb
      ].each do |path|
        file = File.join(root, path)
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
      end
    }

    let(:job) { subject.collect_jobs.first }
    let(:job_files) {
      files = job.to_exec
      end_at = files.index('--').to_i - 1
      files[2..end_at]
    }

    it "finds one job" do
      subject.collect_jobs.size.must_equal 1
    end

    it "tests all files" do
      job_files.must_equal %w[
        test/functional/lib_user_test.rb
        test/unit/blog_test.rb
        test/unit/user_test.rb
      ]
    end

    it "sets ruby options" do
      job.env['RUBYOPT'].must_equal "-Ilib:test %"
    end

    describe "with verbose" do
      let(:options) { {:warnings => true} }

      it "sets warning option" do
        job.env['RUBYOPT'].must_equal "-w -Ilib:test %"
      end
    end

    describe "with pattern" do
      let(:names) { %w[user] }

      it "finds files by pattern" do
        job_files.must_equal %w[
          test/functional/lib_user_test.rb
          test/unit/user_test.rb
        ]
      end
    end

    describe "with directory" do
      let(:names) { %w[unit] }

      it "finds files in dir" do
        job_files.must_equal %w[
          test/unit/blog_test.rb
          test/unit/user_test.rb
        ]
      end
    end

    describe "with non-matching name" do
      let(:names) { %w[nonexist] }

      it "finds no jobs" do
        subject.collect_jobs.must_be_empty
      end
    end

    describe "test filters" do
      describe "from option" do
        let(:options) { {:name_filters => %w'filly'} }

        it "generates test/unit argument" do
          job.to_s.must_include "-- -n /filly/"
        end
      end

      describe "from line numbers" do
        before {
          File.open(File.join(root, 'test/unit/blog_test.rb'), 'w') do |file|
            file.write <<-RUBY
              require 'moo'
              def test_blog
                # normal
              test "has feed"
                # ActiveSupport::TestCase
              it "needs posts" do
                # minitest/spec
              end
              specify('no comments') { ... }
            RUBY
          end
        }

        describe "normal syntax" do
          let(:names) { %w[ test/unit/blog_test.rb:3 ] }
          it("finds method") { job.to_s.must_include "-n /test_blog/" }
        end

        describe "ActiveSupport syntax" do
          let(:names) { %w[ test/unit/blog_test.rb:5 ] }
          it("finds method") { job.to_s.must_include "-n /has_feed/" }
        end

        describe "normal syntax" do
          let(:names) { %w[ test/unit/blog_test.rb:7 ] }
          it("finds method") { job.to_s.must_include "-n /needs posts/" }
        end

        describe "normal syntax" do
          let(:names) { %w[ test/unit/blog_test.rb:9 ] }
          it("finds method") { job.to_s.must_include "-n /no comments/" }
        end
      end
    end
  end

  describe "RSpec project" do
    before {
      %w[ app/models/user.rb
          lib/sync.rb
          spec/models/user_spec.rb
          spec/models/blog_spec.rb
          spec/integration/sync_spec.rb
      ].each do |path|
        file = File.join(root, path)
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
      end
    }

    let(:job) { subject.collect_jobs.first }
    let(:job_files) {
      files = job.to_exec
      files[1..-1]
    }

    it "finds one job" do
      subject.collect_jobs.size.must_equal 1
    end

    it "tests all files" do
      job_files.must_equal %w[spec]
    end

    describe "name args" do
      let(:names) { %w[user blog] }

      it "tests some files" do
        job_files.must_equal %w[
          spec/models/user_spec.rb
          spec/models/blog_spec.rb
        ]
      end
    end

    it "sets no ruby options" do
      job.env['RUBYOPT'].must_be_nil
    end

    describe "example filters" do
      let(:options) { {:name_filters => %w'willy filly'} }

      it "generates arguments" do
        job.to_s.must_include " -e willy -e filly "
      end
    end

    describe "tag filters" do
      let(:options) { {:tag_filters => %w'willy filly'} }

      it "generates arguments" do
        job.to_s.must_include " -t willy -t filly "
      end
    end
  end

  describe "mixed project" do
    before {
      %w[ app/models/user.rb
          lib/sync.rb
          test/unit/test_user.rb
          spec/models/blog_spec.rb
          features/sync.feature
      ].each do |path|
        file = File.join(root, path)
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
      end
    }

    let(:jobs) { subject.collect_jobs }

    it "finds three jobs" do
      jobs.map {|j| j.to_s }.must_equal [
        'polyamory -t test/unit/test_user.rb',
        'rspec spec',
        'cucumber features',
      ]
    end

    describe "with tags" do
      let(:options) { {:tag_filters => %w[willy ~nilly]} }
      it "is filtered by tags" do
        jobs.map {|j| j.to_s }.must_equal [
          'rspec -t willy -t ~nilly spec',
          'cucumber -t @willy -t ~@nilly features',
        ]
      end
    end
  end

end
