require 'minitest/spec'
require 'polyamory/runner'
require 'fileutils'

describe Polyamory::Runner do

  subject { Polyamory::Runner.new(names, root, options) }

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
    let(:job_files) { job.to_s.split('testrb ', 2).last.split(/\s+/).sort }

    it "finds one job" do
      subject.collect_jobs.size.must_equal 1
    end

    it "tests all files" do
      job.to_s.must_include "ruby -Ilib:test -S testrb"
      job_files.must_equal %w[
        test/functional/lib_user_test.rb
        test/unit/blog_test.rb
        test/unit/user_test.rb
      ]
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
        let(:options) { {:test_filter => 'filly'} }

        it "generates test/unit argument" do
          job.to_s.must_include "testrb -n /filly/"
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
          it("finds method") { job.to_s.must_include "-n /needs_posts/" }
        end

        describe "normal syntax" do
          let(:names) { %w[ test/unit/blog_test.rb:9 ] }
          it("finds method") { job.to_s.must_include "-n /no_comments/" }
        end
      end
    end
  end

end
