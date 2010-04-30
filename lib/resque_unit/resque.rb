class Resque

  def self.reset!
    @queue = Hash.new { |h, k| h[k] = [] }
  end

  def self.queue(queue)
    self.reset unless @queue
    @queue[queue]
  end

  def self.enqueue(klass, *args)
    queue(queue_for(klass)) << {:klass => klass, :args => args}
  end

  def self.queue_for(klass)
    klass.instance_variable_get(:@queue)
  end

end
