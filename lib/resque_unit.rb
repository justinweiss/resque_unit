module ResqueUnit
end

require 'resque_unit/resque'
require 'resque_unit/assertions'


Test::Unit::TestCase.send(:include, ResqueUnit::Assertions)

