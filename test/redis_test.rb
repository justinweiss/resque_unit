require 'test_helper'

describe Redis do
  it "uses a real Redis connection by default" do
    redis = Redis.current
    refute_equal Redis::Connection::Memory, redis.client.driver

    redis = Redis.new
    refute_equal Redis::Connection::Memory, redis.client.driver
  end
end
