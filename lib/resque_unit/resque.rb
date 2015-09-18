# The fake Resque class. This needs to be loaded after the real Resque
# for the assertions in +ResqueUnit::Assertions+ to work.
module Resque
  include ResqueUnit::Helpers
  extend self

  # Resets all the queues to the empty state. This should be called in
  # your test's +setup+ method until I can figure out a way for it to
  # automatically be called.
  #
  # If <tt>queue_name</tt> is given, then resets only that queue.
  def reset!(queue = nil)
    if queue
      remove_queue(queue)
    else
      redis.flushall
    end
  end

  # Return an array of all jobs' payloads for queue
  # Elements are decoded
  def all(queue_name)
    jobs = peek(queue_name, 0, size(queue_name))
    jobs.kind_of?(Array) ? jobs : [jobs]
  end
  alias queue all

  # Yes, all Resque hooks!
  def enable_hooks!
    @hooks_enabled = true
  end

  def disable_hooks!
    @hooks_enabled = nil
  end

  # Executes all jobs in all queues in an undefined order.
  def run!
    payloads = []
    queues.each do |queue|
      size(queue).times { payloads << pop(queue) }
    end
    exec_payloads payloads.shuffle
  end

  def run_for!(queue, limit = Float::INFINITY)
    job_count = [limit, size(queue)].min
    payloads = []

    job_count.times { payloads << pop(queue) }
    exec_payloads payloads.shuffle
  end

  def exec_payloads(raw_payloads)
    raw_payloads.each do |raw_payload|
      Resque::Job.new(:inline, raw_payload).perform
    end
  end
  
  private :exec_payloads

  # 1. Execute all jobs in all queues in an undefined order,
  # 2. Check if new jobs were announced, and execute them.
  # 3. Repeat 3
  def full_run!
    run! until queues.all? { |queue| size(queue) == 0 }
  end
end
