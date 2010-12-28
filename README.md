# Polyamory

Polyamory loves *all* of your testing frameworks. It is a command-line tool that is able to run your test files regardless of the framework being used.

Features:

* easily run the full test suite for any project: just type `polyamory`
* use a directory name on the command line to run everything inside that directory
* use a keyword to run all test files which contain that word
* Bundler support

Frameworks supported:

* Cucumber in `"features/**/*.feature"`
* RSpec + Shoulda in `"spec/**/*_spec.rb"`
* test/unit, Shoulda, or anything else in `"test/**/*_test.rb"`

## Examples

Here, `polyamory` is aliased as `pam` for brevity.

    # run everything
    $ pam
    > rspec spec &&
      cucumber -f progress -t ~@wip features &&
      polyamory -t test
    
    # everyting inside a single directory
    $ pam test/unit
    > polyamory -t test/unit
    
    # run test files matching keyword
    $ pam user
    > polyamory -t spec/models/user_spec.rb spec/controllers/user_controller.rb &&
      cucumber -f progress -t ~@wip features/user_registration.feature 