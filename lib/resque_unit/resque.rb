# The fake Resque class. This needs to be loaded after the real Resque
# for the assertions in +ResqueUnit::Assertions+ to work.
module Resque

  # Resets all the queues to the empty state. This should be called in
  # your test's +setup+ method until I can figure out a way for it to
  # automatically be called.
  #
  # If <tt>queue_name</tt> is given, then resets only that queue.
  def self.reset!(queue_name = nil)
    if @queue && queue_name
      @queue[queue_name] = []
    else
      @queue = Hash.new { |h, k| h[k] = [] }
    end
  end

  # Returns an array of all the jobs that have been queued. Each
  # element is of the form +{:klass => klass, :args => args}+ where
  # +klass+ is the job's class and +args+ is an array of the arguments
  # passed to the job.
  def self.queue(queue_name)
    self.reset! unless @queue
    @queue[queue_name]
  end

  # Executes all jobs in all queues in an undefined order.
  def self.run!
    old_queue = @queue.dup
    self.reset!

    old_queue.each do |k, v|
      while job = v.shift
        job[:klass].perform(*job[:args])
      end
    end
  end

  # Executes all jobs in the given queue in an undefined order.
  def self.run_for!(queue_name)
    jobs = self.queue(queue_name)
    self.reset!(queue_name)

    while job = jobs.shift
      job[:klass].perform(*job[:args])
    end
  end

  # Returns the size of the given queue
  def self.size(queue_name)
    self.reset! unless @queue
    @queue[queue_name].length
  end

  # :nodoc: 
  def self.enqueue(klass, *args)
    queue(queue_for(klass)) << {:klass => klass, :args => args}
  end

  # :nodoc: 
  def self.queue_for(klass)
    klass.instance_variable_get(:@queue) || (klass.respond_to?(:queue) && klass.queue)
  end

end
