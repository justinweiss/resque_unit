class Resque

  def self.queue(queue)
    @queue ||= Hash.new { |h, k| h[k] = [] }
    @queue[queue]
  end

  def self.enqueue(klass, *args)
    queue(queue_for(klass)) << klass
  end

  def self.queue_for(klass)
    klass.instance_variable_get(:@queue)
  end

end
