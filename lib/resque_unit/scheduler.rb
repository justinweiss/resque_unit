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

    def enqueue_at_with_queue(queue, timestamp, klass, *args)
      enqueue_with_queue_and_timestamp(queue, timestamp, klass, *args)
    end

    # Identical to enqueue_at but takes number_of_seconds_from_now
    # instead of a timestamp.
    def enqueue_in(number_of_seconds_from_now, klass, *args)
      enqueue_at(Time.now + number_of_seconds_from_now, klass, *args)
    end

    def enqueue_in_with_queue(queue, number_of_seconds_from_now, klass, *args)
      enqueue_at_with_queue(queue, Time.now + number_of_seconds_from_now, klass, *args)
    end

    def enqueue_with_timestamp(timestamp, klass, *args)
      enqueue_with_queue_and_timestamp(queue_for(klass), timestamp, klass, *args)
    end

    def enqueue_with_queue_and_timestamp(queue, timestamp, klass, *args)
      enqueue_unit(queue, {"class" => klass.to_s, "args" => args, "timestamp" => timestamp})
    end
    
    def delayed?(klass, *args)
      encoded_job_payloads = Resque.queue(queue_for(klass))
      args ||= []
      encoded_job_payloads.select { |e| e = Resque.decode(e); e["class"] == klass.to_s && e["args"] == args }.present?
    end

    def remove_delayed(klass, *args)
      # points to real queue
      encoded_job_payloads = Resque.queue(queue_for(klass))
      args ||= []
      encoded_job_payloads.delete_if { |e| e = Resque.decode(e); e["class"] == klass.to_s && e["args"] == args }
    end

    def remove_delayed_job_from_timestamp(timestamp, klass, *args)
      encoded_job_payloads = Resque.queue(queue_for(klass))
      args ||= []
      encoded_job_payloads.delete_if { |e| e = Resque.decode(e); e["class"] == klass.to_s && Time.parse(e["timestamp"]).to_i == Time.parse(timestamp.to_s).to_i && e["args"] == args }
    end
  end

  Resque.send(:extend, Scheduler)
end
