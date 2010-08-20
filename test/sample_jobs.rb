class LowPriorityJob
  @queue = :low
  @run = false
  def self.perform
    self.run = true
  end

  def self.run?
    @run
  end

  def self.run=(value)
    @run = value
  end
end

class MediumPriorityJob
  def self.queue
    :medium
  end
end

class HighPriorityJob
  @queue = :high

  def self.perform
  end
end

class JobWithArguments
  @queue = :medium

  def self.perform(num, text)

  end
end

class JobThatCreatesANewJob
  @queue = :spawn

  def self.perform
    Resque.enqueue(LowPriorityJob)
  end
end
