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
      enqueue_unit(queue_for(klass), {:klass => klass, :args => decode(encode(args)), :timestamp => timestamp})
    end

  end

  Resque.send(:extend, Scheduler)
end

