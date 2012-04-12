require 'set'

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
    assert_job_created(queue_name, klass, args, message, &block)
  end
  alias assert_queues assert_queued

  def assert_queued_partial(klass, args = nil, message = nil, &block)
    queue_name = Resque.queue_for(klass)
    assert_job_created_partial(queue_name, klass, args, message, &block)
  end
  alias assert_queues_partial assert_queued_partial
    
  # The opposite of +assert_queued+.
  def assert_not_queued(klass = nil, args = nil, message = nil, &block)
    queue_name = Resque.queue_for(klass)

    queue = if block_given?
      snapshot = Resque.size(queue_name)
      yield
      Resque.all(queue_name)[snapshot..-1]
    else
      Resque.all(queue_name)
    end

    assert_with_custom_message(!in_queue?(queue, klass, args),
      message || "#{klass}#{args ? " with #{args.inspect}" : ""} should not have been queued in #{queue_name}.")
  end
  
  # assert that a job was created and queued into the specific queue with at least the given arguments different from what's given
  def assert_not_queued_partial(klass, args = nil, message = nil, &block)
    queue_name = Resque.queue_for(klass)
    assert_job_not_created_partial(queue_name, klass, args, message, &block)
  end
  
  # Asserts no jobs were queued within the block passed.
  def assert_nothing_queued(message = nil, &block)
    snapshot = Resque.size
    yield
    present = Resque.size
    assert_equal snapshot, present, message || "No jobs should have been queued"
  end

  # Asserts that a job was created and queued into the specified queue
  def assert_job_created(queue_name, klass, args = nil, message = nil, &block)
    queue = if block_given?
      snapshot = Resque.size(queue_name)
      yield
      Resque.all(queue_name)[snapshot..-1]
    else
      Resque.all(queue_name)
    end

    assert_with_custom_message(in_queue?(queue, klass, args),
      message || "#{klass}#{args ? " with #{args.inspect}" : ""} should have been queued in #{queue_name}: #{queue.inspect}.")
  end

  def assert_job_created_partial(queue_name, klass, args = nil, message = nil, &block)
    queue = if block_given?
      snapshot = Resque.size(queue_name)
      yield
      Resque.all(queue_name)[snapshot..-1]
    else
      Resque.all(queue_name)
    end

    assert_with_custom_message(in_queue_partial?(queue, klass, args),
      message || "#{klass}#{args ? " with #{args.inspect}" : ""} should have been queued in #{queue_name}: #{queue.inspect}.")
  end
  
  def assert_job_not_created_partial(queue_name, klass, args = nil, message = nil, &block)
    queue = if block_given?
      snapshot = Resque.size(queue_name)
      yield
      Resque.all(queue_name)[snapshot..-1]
    else
      Resque.all(queue_name)
    end
    
    assert_with_custom_message(!in_queue_partial?(queue, klass, args),
      message || "#{klass}#{args ? " with #{args.inspect}" : ""} should not have been queued in #{queue_name}: #{queue.inspect}.")
  end
  
  private

  # In Test::Unit, +assert_block+ displays only the message on a test
  # failure and +assert+ always appends a message to the end of the
  # passed-in assertion message. In MiniTest, it's the other way
  # around. This abstracts those differences and never appends a
  # message to the one the user passed in.
  def assert_with_custom_message(value, message = nil)
    if defined?(MiniTest::Assertions)
      assert value, message
    else
      assert_block message do
        value
      end
    end
  end
  
  def in_queue?(queue, klass, args = nil)
    !matching_jobs(queue, klass, args).empty?
  end
  
  def matching_jobs(queue, klass, args = nil)
    normalized_args = Resque.decode(Resque.encode(args)) if args
    queue.select {|e| e["class"] == klass.to_s && (!args || e["args"] == normalized_args )}
  end
  
  def in_queue_partial?(queue, klass, args = nil)
    normalized_args = Resque.decode(Resque.encode(args)).to_set if args
    
    queue.each do |e| 
       if e["class"] == klass.to_s then
         if args
           return true if normalized_args.subset?(e["args"].to_set) 
           e["args"].each do |current_arg|
             return true if (current_arg.is_a?(Array) || current_arg.is_a?(Hash)) && normalized_args.subset?(current_arg.to_set) 
           end
         else
           return true
         end
       end
    end
    
    false
  end

end
