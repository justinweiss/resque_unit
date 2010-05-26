# These are a group of assertions you can use in your unit tests to
# verify that your code is using Resque correctly.
module ResqueUnit::Assertions
  
  # Asserts that +klass+ has been queued into its appropriate queue at
  # least once. If +args+ is nil, it only asserts that the klass has
  # been queued. Otherwise, it asserts that the klass has been queued
  # with the correct arguments. Pass an empty array for +args+ if you
  # want to assert that klass has been queued without arguments.
  def assert_queued(klass, args = nil, message = nil)
    queue = Resque.queue_for(klass)
    assert_block (message || "#{klass} should have been queued in #{queue}: #{Resque.queue(queue).inspect}.") do 
      in_queue?(queue, klass, args)
    end
  end

  # The opposite of +assert_queued+.
  def assert_not_queued(klass, args = nil, message = nil)
    queue = Resque.queue_for(klass)
    assert_block (message || "#{klass} should not have been queued in #{queue}.") do 
      !in_queue?(queue, klass, args)
    end
  end

  private

  def in_queue?(queue, klass, args = nil)
    !matching_jobs(queue, klass, args).empty?
  end

  def matching_jobs(queue, klass, args = nil)
    if args # retrieve the elements that match klass and args in the queue
      Resque.queue(queue).select {|e| e[:klass] == klass && e[:args] == args}
    else # if no args were passed, retrieve all queued jobs that match klass
      Resque.queue(queue).select {|e| e[:klass] == klass}
    end
  end

end
