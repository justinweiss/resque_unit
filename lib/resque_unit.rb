module ResqueUnit
end

require 'test/unit'
require 'resque_unit/resque'
require 'resque_unit/errors'
require 'resque_unit/assertions'


Test::Unit::TestCase.send(:include, ResqueUnit::Assertions)

