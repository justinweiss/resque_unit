# The fake Resque class. This needs to be loaded after the real Resque
# for the assertions in +ResqueUnit::Assertions+ to work.
module Resque
  include Helpers
  extend self

  # Resets all the queues to the empty state. This should be called in
  # your test's +setup+ method until I can figure out a way for it to
  # automatically be called.
  #
  # If <tt>queue_name</tt> is given, then resets only that queue.
  def reset!(queue_name = nil)
    if @queue && queue_name
      @queue[queue_name] = []
    else
      @queue = Hash.new { |h, k| h[k] = [] }
    end
  end

  # Returns a hash of all the queue names and jobs that have been queued. The
  # format is <tt>{queue_name => [job, ..]}</tt>.
  def self.queues
    @queue || reset!
  end

  # Returns an array of all the jobs that have been queued. Each
  # element is of the form +{:klass => klass, :args => args}+ where
  # +klass+ is the job's class and +args+ is an array of the arguments
  # passed to the job.
  def queue(queue_name)
    queues[queue_name]
  end

  # Executes all jobs in all queues in an undefined order.
  def run!
    old_queue = @queue.dup
    self.reset!

    old_queue.each do |k, v|
      while job = v.shift
        job[:klass].perform(*job[:args])
      end
    end
  end

  # Executes all jobs in the given queue in an undefined order.
  def run_for!(queue_name)
    jobs = self.queue(queue_name)
    self.reset!(queue_name)

    while job = jobs.shift
      job[:klass].perform(*job[:args])
    end
  end

  # 1. Execute all jobs in all queues in an undefined order,
  # 2. Check if new jobs were announced, and execute them.
  # 3. Repeat 3
  def full_run!
    until empty_queues?
      queues.each do |k, v|
        while job = v.shift
          job[:klass].perform(*job[:args])
        end
      end
    end
  end

  # Returns the size of the given queue
  def size(queue_name = nil)
    if queue_name
      queues[queue_name].length
    else
      queues.values.flatten.length
    end
  end

  # :nodoc: 
  def enqueue(klass, *args)
    queue_name = queue_for(klass)
    # Behaves like Resque, raise if no queue was specifed
    raise NoQueueError.new("Jobs must be placed onto a queue.") unless queue_name
    queue(queue_name) << {:klass => klass, :args => decode(encode(args))}
  end

  # :nodoc: 
  def queue_for(klass)
    klass.instance_variable_get(:@queue) || (klass.respond_to?(:queue) && klass.queue)
  end

  # :nodoc:
  def empty_queues?
    queues.all? do |k, v|
      v.empty?
    end
  end

end
