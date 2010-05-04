# The fake Resque class. This needs to be loaded after the real Resque
# for the assertions in +ResqueUnit::Assertions+ to work.
module Resque

  # Resets all the queues to the empty state. This should be called in
  # your test's +setup+ method until I can figure out a way for it to
  # automatically be called.
  def self.reset!
    @queue = Hash.new { |h, k| h[k] = [] }
  end

  # Returns an array of all the jobs that have been queued. Each
  # element is of the form +{:klass => klass, :args => args}+ where
  # +klass+ is the job's class and +args+ is an array of the arguments
  # passed to the job.
  def self.queue(queue)
    self.reset unless @queue
    @queue[queue]
  end

  # Executes all jobs in all queues in an undefined order.
  def self.run!
    @queue.each do |k, v|
      while job = v.shift
        job[:klass].perform(*job[:args])
      end
    end
  end

  # :nodoc: 
  def self.enqueue(klass, *args)
    queue(queue_for(klass)) << {:klass => klass, :args => args}
  end

  # :nodoc: 
  def self.queue_for(klass)
    klass.instance_variable_get(:@queue)
  end

end
