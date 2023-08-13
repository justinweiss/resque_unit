module ResqueUnit
end

begin
  require 'yajl'
rescue LoadError
  require 'json'
end

require 'resque_unit/helpers'
require 'resque_unit/resque'
require 'resque_unit/errors'
require 'resque_unit/assertions'
require 'resque_unit/plugin'

if defined?(Test::Unit::TestCase)
  Test::Unit::TestCase.send(:include, ResqueUnit::Assertions)
end

if defined?(Minitest::Unit::TestCase)
  Minitest::Unit::TestCase.send(:include, ResqueUnit::Assertions)
end

if defined?(Minitest::Test)
  Minitest::Test.send(:include, ResqueUnit::Assertions)
end
