class LowPriorityJob
  @queue = :low

  def self.perform
  end
end

class JobWithArguments
  @queue = :medium

  def self.perform(num, text)

  end
end
