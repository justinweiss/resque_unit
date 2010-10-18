# Re-define errors in from Resque, in case the 'resque' gem was not loaded.
module Resque
  # Raised whenever we need a queue but none is provided.
  unless defined?(NoQueueError)
    class NoQueueError < RuntimeError; end
  end

  # Raised when trying to create a job without a class
  unless defined?(NoClassError)
    class NoClassError < RuntimeError; end
  end
  
  # Raised when a worker was killed while processing a job.
  unless defined?(DirtyExit)
    class DirtyExit < RuntimeError; end
  end
end
