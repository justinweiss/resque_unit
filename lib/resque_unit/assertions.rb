# These are a group of assertions you can use in your unit tests to
# verify that your code is using Resque correctly.
module ResqueUnit::Assertions
  
  # Asserts that +klass+ has been queued into its appropriate queue at
  # least once. If +args+ is nil, it only asserts that the klass has
  # been queued. Otherwise, it asserts that the klass has been queued
  # with the correct arguments. Pass an empty array for +args+ if you
  # want to assert that klass has been queued without arguments. Pass a block
  # if you want to assert something was queued within its execution.
  def assert_queued(klass, args = nil, message = nil, &block)
    queue_name = Resque.queue_for(klass)

    queue = if block_given?
      snapshot = Resque.queue(queue_name).dup
      yield
      Resque.queue(queue_name) - snapshot
    else
      Resque.queue(queue_name)
    end

    assert_block (message || "#{klass}#{args ? " with #{args.inspect}" : ""} should have been queued in #{queue_name}: #{queue.inspect}.") do
      in_queue?(queue, klass, args)
    end
  end
  alias assert_queues assert_queued

  # The opposite of +assert_queued+.
  def assert_not_queued(klass = nil, args = nil, message = nil, &block)
    queue_name = Resque.queue_for(klass)

    queue = if block_given?
      snapshot = Resque.queue(queue_name).dup
      yield
      Resque.queue(queue_name) - snapshot
    else
      Resque.queue(queue_name)
    end

    assert_block (message || "#{klass}#{args ? " with #{args.inspect}" : ""} should not have been queued in #{queue_name}.") do
      !in_queue?(queue, klass, args)
    end
  end

  private

  def in_queue?(queue, klass, args = nil)
    !matching_jobs(queue, klass, args).empty?
  end

  def matching_jobs(queue, klass, args = nil)
    queue = Resque.queue(queue) if queue.is_a? Symbol
    if args # retrieve the elements that match klass and args in the queue
      queue.select {|e| e[:klass] == klass && e[:args] == args}
    else # if no args were passed, retrieve all queued jobs that match klass
      queue.select {|e| e[:klass] == klass}
    end
  end

end
