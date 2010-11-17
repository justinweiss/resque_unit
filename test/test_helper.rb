require 'rubygems'
require 'shoulda'
require 'resque_unit'
require 'sample_jobs'

# Fix shoulda under 1.9.2. See https://github.com/thoughtbot/shoulda/issues/issue/117
unless defined?(Test::Unit::AssertionFailedError)
  Test::Unit::AssertionFailedError = MiniTest::Assertion
end
