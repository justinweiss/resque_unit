require 'resque_unit/scheduler'
require 'resque_unit/scheduler_assertions'

if defined?(Test::Unit::TestCase)
  Test::Unit::TestCase.send(:include, ResqueUnit::SchedulerAssertions)
end

if defined?(MiniTest::Unit::TestCase)
  MiniTest::Unit::TestCase.send(:include, ResqueUnit::SchedulerAssertions)
end

if defined?(Minitest::Test)
  Minitest::Test.send(:include, ResqueUnit::SchedulerAssertions)
end
