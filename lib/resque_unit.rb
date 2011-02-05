module ResqueUnit
end

begin
  require 'yajl'
rescue LoadError
  require 'json'
end

require 'test/unit'
require 'resque_unit/helpers'
require 'resque_unit/resque'
require 'resque_unit/errors'
require 'resque_unit/assertions'
require 'resque_unit/plugin' 

Test::Unit::TestCase.send(:include, ResqueUnit::Assertions)

