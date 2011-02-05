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

  def self.perform(num, text, hash)

  end
end

class JobThatCreatesANewJob
  @queue = :spawn

  def self.perform
    Resque.enqueue(LowPriorityJob)
  end
end

class JobThatDoesNotSpecifyAQueue
  
  def self.perform
  end
end

class JobWithHooks
  @queue = :with_hooks
  @markers = {}
  
  def self.perform
    raise 'FAIL!' if @will_fail
  end
  
  def self.markers
    @markers
  end
  
  def self.clear_markers
    @markers = {}
  end
  
  def self.after_enqueue_mark(*args)
    markers[:after_enqueue] = true
  end
  
  def self.before_perform_mark(*args)
    markers[:before] = true
  end
  
  def self.around_perform_mark(*args)
    markers[:around] = true
    if @dont_perform
      raise Resque::Job::DontPerform
    else
      yield
    end
  end
  
  def self.after_perform_mark(*args)
    markers[:after] = true
  end
  
  def self.failure_perform_mark(*args)
    markers[:failure] = true
  end
  
  def self.make_it_fail(&block)
    @will_fail = true
    yield
  ensure
    @will_fail = false
  end
  
  def self.make_it_dont_perform(&block)
    @dont_perform = true
  ensure
    @dont_perform = false
  end
  
end