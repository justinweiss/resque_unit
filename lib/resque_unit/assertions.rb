module ResqueUnit::Assertions

  def assert_queued(klass, message = nil)
    queue = Resque.queue_for(klass)
    assert_block (message || "#{klass} should have been queued in #{queue}: #{Resque.queue(queue).inspect}.") do 
      Resque.queue(queue).include?(klass)
    end
  end
  
end
