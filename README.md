# Polyamory – the promiscuous test runner

Polyamory is a command-line tool that knows how to run your tests regardless of
the framework. It can either run the whole test suite or filter by keywords,
test case names, or tags. It remembers the differences between arguments for
different testing frameworks so you don't have to.

Frameworks supported:

* Cucumber in `features/**/*.feature`
* RSpec + Shoulda in `spec/**/*_spec.rb`
* test/unit, Shoulda, or anything else in `test/**/*_test.rb` or `test/**/test*.rb`

Features:

*   `polyamory` - Runs the full test suite for any project. For example, it will
    run all of the following:

        rspec spec
        cucumber features
        ruby -e 'ARGV.each {|f| require f }' test/**/*_test.rb

*   `polyamory <dirname>` - Runs all tests inside a subdirectory. For example:

        polyamory models
        -> runs test/models/**/*_test.rb
        -> runs spec/models/**/*_spec.rb

*   `polyamory <keyword>` - Runs all test files that match a keyword. For example:

        polyamory search
        -> runs test/models/user_search_test.rb
        -> runs spec/controllers/search_controller_spec.rb
        -> runs features/site_search.feature

*   `polyamory <file>:<line>` - Runs focused test. Provides this feature for
    test/unit and minitest which don't support it.

*   `polyamory -n <pattern>` - Runs only tests whose names match given patterns.

*   `polyamory -t <tag>` - Runs RSpec/Cucumber tests that match given tags.
    Tag exclusion is done with `~<tag>`. Tag names are normalized for Cucumber
    (which expects them in form of `@<tag>`).
