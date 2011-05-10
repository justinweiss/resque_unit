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

  # Returns an array of jobs' payloads currently queued.
  #
  # start and count should be integer and can be used for pagination.
  # start is the item to begin, count is how many items to return.
  #
  # To get the 3rd page of a 30 item, paginatied list one would use:
  #   Resque.peek('my_list', 59, 30)
  def peek(queue_name, start = 0, count = 1)
    list_range(queue_name, start, count)
  end

  # Gets a range of jobs' payloads from queue.
  # Returns single element if count equal 1
  def list_range(key, start = 0, count = 1)
    if count == 1
      queues[key][start]
    else
      queues[key][start...start + count] || []
    end
  end

  # Yes, all Resque hooks!
  def enable_hooks!
    @hooks_enabled = true
  end

  def disable_hooks!
    @hooks_enabled = nil
  end

  # Executes all jobs in all queues in an undefined order.
  def run!
    old_queue = @queue.dup
    self.reset!

    old_queue.each do |k, v|
      while job = v.shift
        @hooks_enabled ? perform_with_hooks(job) : perform_without_hooks(job)
      end
    end
  end

  # Executes all jobs in the given queue in an undefined order.
  def run_for!(queue_name)
    jobs = self.queue(queue_name)
    self.reset!(queue_name)

    while job = jobs.shift
      @hooks_enabled ? perform_with_hooks(job) : perform_without_hooks(job)
    end
  end

  # 1. Execute all jobs in all queues in an undefined order,
  # 2. Check if new jobs were announced, and execute them.
  # 3. Repeat 3
  def full_run!
    run! until empty_queues?
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
    enqueue_unit(queue_name, {:klass => klass, :args => normalized_args(args) })
  end

  def normalized_args(args)
    decode(encode(args))
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

  def enqueue_unit(queue_name, hash)
    queue(queue_name) << hash
    if @hooks_enabled
      Plugin.after_enqueue_hooks(hash[:klass]).each do |hook|
        hash[:klass].send(hook, *hash[:args])
      end
    end
    queue(queue_name).size
  end

  # Call perform on the job class
  def perform_without_hooks(job)
    job[:klass].perform(*job[:args])
  end

  # Call perform on the job class, and adds support for Resque hooks.
  def perform_with_hooks(job)
    before_hooks  = Resque::Plugin.before_hooks(job[:klass])
    around_hooks  = Resque::Plugin.around_hooks(job[:klass])
    after_hooks   = Resque::Plugin.after_hooks(job[:klass])
    failure_hooks = Resque::Plugin.failure_hooks(job[:klass])
    
    begin
      # Execute before_perform hook. Abort the job gracefully if
      # Resque::DontPerform is raised.
      begin
        before_hooks.each do |hook|
          job[:klass].send(hook, *job[:args])
        end
      rescue Resque::Job::DontPerform
        return false
      end
      
      # Execute the job. Do it in an around_perform hook if available.
      if around_hooks.empty?
        perform_without_hooks(job)
        job_was_performed = true
      else
        # We want to nest all around_perform plugins, with the last one
        # finally calling perform
        stack = around_hooks.reverse.inject(nil) do |last_hook, hook|
          if last_hook
            lambda do
              job[:klass].send(hook, *job[:args]) { last_hook.call }
            end
          else
            lambda do
              job[:klass].send(hook, *job[:args]) do
                result = perform_without_hooks(job)
                job_was_performed = true
                result
              end
            end
          end
        end
        stack.call
      end
      
      # Execute after_perform hook
      after_hooks.each do |hook|
        job[:klass].send(hook, *job[:args])
      end
      
      # Return true if the job was performed
      return job_was_performed
      
    # If an exception occurs during the job execution, look for an
    # on_failure hook then re-raise.
    rescue => e
      failure_hooks.each { |hook| job[:klass].send(hook, e, *job[:args]) }
      raise e
    end
  end

  class Job
    extend Helpers
    def self.create(queue, klass_name, *args)
      Resque.enqueue_unit(queue, {:klass => constantize(klass_name), :args => decode(encode(args))})
    end
  end

end
