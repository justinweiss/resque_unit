# These are a group of assertions you can use in your unit tests to
# verify that your code is using resque-scheduler correctly.
require 'time'

module ResqueUnit::SchedulerAssertions
  
  # Asserts that +klass+ has been queued into its appropriate queue at
  # least once, with a +timestamp+ less than or equal to
  # +expected_timestamp+. If the job wasn't queued with a timestamp,
  # the assertion fails.. If +args+ is nil, it only asserts that the
  # klass has been queued. Otherwise, it asserts that the klass has
  # been queued with the correct arguments. Pass an empty array for
  # +args+ if you want to assert that klass has been queued without
  # arguments.
  def assert_queued_at(expected_timestamp, klass, args = nil, message = nil)
    queue = Resque.queue_for(klass)
    assert in_timestamped_queue?(queue, expected_timestamp, klass, args),
      (message || "#{klass} should have been queued in #{queue} before #{expected_timestamp}: #{Resque.queue(queue).inspect}.")
  end

  # Similar to +assert_queued_at+, except it takes an expected time
  # difference (in seconds) instead of a timestamp.
  def assert_queued_in(expected_time_difference, klass, args = nil, message = nil)
    assert_queued_at(Time.now + expected_time_difference, klass, args, message)
  end
  
  # opposite of +assert_queued_at+
  def assert_not_queued_at(expected_timestamp, klass, args = nil, message = nil)
    queue = Resque.queue_for(klass)
    assert !in_timestamped_queue?(queue, expected_timestamp, klass, args),
      (message || "#{klass} should not have been queued in #{queue} before #{expected_timestamp}.")
  end

  # opposite of +assert_queued_in+
  def assert_not_queued_in(expected_time_difference, klass, args = nil, message = nil)
    assert_not_queued_at(Time.now + expected_time_difference, klass, args, message)
  end

  private

  def in_timestamped_queue?(queue_name, expected_timestamp, klass, args = nil)
    # check if we have any matching jobs with a timestamp less than
    # expected_timestamp
    !matching_jobs(Resque.all(queue_name), klass, args).select {|e| e["timestamp"] && Time.parse(e["timestamp"]) <= expected_timestamp}.empty?
  end
  
end
