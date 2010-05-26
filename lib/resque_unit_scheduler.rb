require 'resque_unit/scheduler'
require 'resque_unit/scheduler_assertions'

Test::Unit::TestCase.send(:include, ResqueUnit::SchedulerAssertions)
