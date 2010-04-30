module ResqueUnit::Assertions

  def assert_queued(klass, args = nil, message = nil)
    queue = Resque.queue_for(klass)
    assert_block (message || "#{klass} should have been queued in #{queue}: #{Resque.queue(queue).inspect}.") do 
      in_queue?(queue, klass, args)
    end
  end

  def assert_not_queued(klass, args = nil, message = nil)
    queue = Resque.queue_for(klass)
    assert_block (message || "#{klass} should have been queued in #{queue}.") do 
      !in_queue?(queue, klass, args)
    end
  end

  private

  def in_queue?(queue, klass, args = nil)
    if args # verify the klass and args match some element in the queue
      !Resque.queue(queue).select {|e| e[:klass] == klass && e[:args] == args}.empty?
    else # if no args were passed, just verify the job is in the queue
      !Resque.queue(queue).select {|e| e[:klass] == klass}.empty?
    end
  end
  
end
