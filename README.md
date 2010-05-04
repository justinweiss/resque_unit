ResqueUnit
==========
http://github.com/justinweiss/resque_unit

ResqueUnit provides some extra assertions and a mock Resque for
testing Rails code that depends on Resque. You can install it as
either a gem or a plugin:

    gem install resque_unit

and in your test.rb: 

    config.gem 'resque_unit'

If you'd rather install it as a plugin, you should be able to run

    script/plugin install git://github.com/justinweiss/resque_unit.git

inside your Rails projects. 

Example
=======

ResqueUnit provides some extra assertions for your unit tests. For
example, if you have code that queues a resque job:

    class MyJob
      @queue = :low  
    
      def self.perform(x)
        // do stuff
      end
    end
    
    def queue_job
      Resque.enqueue(MyJob, 1)
    end

You can write a unit test for code that queues this job:

    def test_job_queued
      queue_job
      assert_queued(MyJob) # assert that MyJob was queued in the :low queue
    end

You can also verify that a job was queued with arguments:

    def test_job_queued_with_arguments
      queue_job
      assert_queued(MyJob, [1])
    end

And you can run all the jobs in the queue, so you can verify that they
run correctly:

   def test_job_runs 
     queue_job 
     Resque.run!
     assert stuff_was_done, "Job didn't run"
   end

You can also access the queues directly:

    def test_jobs_in_queue
      queue_job 
      assert_equal 1, Resque.queue(:low).length
    end

Caveats
=======

* You should make sure that you call `Resque.reset!` in your test's
  setup method to clear all of the test queues.

Copyright (c) 2010 Justin Weiss, released under the MIT license
