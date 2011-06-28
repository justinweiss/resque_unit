module ResqueUnit
  
  # ResqueUnit::Scheduler is a group of functions mocking the behavior
  # of resque-scheduler. It is included into Resque when
  # 'resque_unit_scheduler' is required.
  module Scheduler

    # takes a timestamp which will be used to schedule the job
    # for queueing.  Until timestamp is in the past, the job will
    # sit in the schedule list.
    def enqueue_at(timestamp, klass, *args)
      enqueue_with_timestamp(timestamp, klass, *args)
    end
    
    # Identical to enqueue_at but takes number_of_seconds_from_now
    # instead of a timestamp.
    def enqueue_in(number_of_seconds_from_now, klass, *args)
      enqueue_at(Time.now + number_of_seconds_from_now, klass, *args)
    end
    
    def enqueue_with_timestamp(timestamp, klass, *args)
      enqueue_unit(queue_for(klass), {"class" => klass, "args" => args, "timestamp" => timestamp})
    end

    def remove_delayed(klass, *args)
      # points to real queue
      encoded_job_payloads = Resque.queue(queue_for(klass))
      args ||= []
      encoded_job_payloads.delete_if { |e| e = Resque.decode(e); e["class"] == klass.to_s && e["args"] == args }
    end
  end

  Resque.send(:extend, Scheduler)
end

