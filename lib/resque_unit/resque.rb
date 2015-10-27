require 'resque'
require 'resque_unit/resque/test_extensions'

# This is a little weird. Fakeredis registers itself as the default
# redis driver after you load it. This might not be what you want,
# though -- resque_unit needs fakeredis, but you may have a reason to
# use a different redis driver for the rest of your test code. So
# we'll store the old default here, and restore it afer we're done
# loading fakeredis. Then, we'll point resque at fakeredis
# specifically.
default_redis_driver = Redis::Connection.drivers.pop
require 'fakeredis'
Redis::Connection.drivers << default_redis_driver if default_redis_driver

Resque.extend Resque::TestExtensions
