# The fake Resque class. This needs to be loaded after the real Resque
# for the assertions in +ResqueUnit::Assertions+ to work.
class Resque

  # Resets all the queues to the empty state. This should be called in
  # your test's +setup+ method until I can figure out a way for it to
  # automatically be called.
  def self.reset!
    @queue = Hash.new { |h, k| h[k] = [] }
  end

  def self.queue(queue)
    self.reset unless @queue
    @queue[queue]
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
