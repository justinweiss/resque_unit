require 'test_helper'

class ResqueUnitTest < ActiveSupport::TestCase

  setup do
    # should probably happen automatically, but I haven't thought of a
    # good way to hook setup() yet.
    Resque.reset!
  end
  
  context "A task that schedules a resque job" do
    setup do 
      Resque.enqueue(LowPriorityJob)
    end

    should "pass the assert_queued(job) assertion" do 
      assert_queued(LowPriorityJob)
    end

    should "fail the assert_not_queued(job) assertion" do 
      assert_raise Test::Unit::AssertionFailedError do 
        assert_not_queued(LowPriorityJob)
      end
    end

    context ", when Resque.run! is called," do 
      setup do 
        assert !LowPriorityJob.run?, "The job should not have been run yet"
        Resque.run!
      end
      
      teardown do 
        LowPriorityJob.run = false
      end

      should "run the job" do 
        assert LowPriorityJob.run?, "The job should have run"
      end
    end

    # assert number of jobs?
  end

  context "An empty queue" do
    should "pass the assert_not_queued(job) assertion" do 
      assert_not_queued(LowPriorityJob)
    end

    should "fail the assert_queued(job) assertion" do
      assert_raise Test::Unit::AssertionFailedError do 
        assert_queued(LowPriorityJob)
      end
    end
  end
  
  context "A task that schedules a resque job with arguments" do 
    setup do 
      Resque.enqueue(JobWithArguments, 1, "test")
    end
    
    should "pass the assert_queued(job, *args) assertion if the args match" do
      assert_queued(JobWithArguments, [1, "test"])
    end
    
    should "pass the assert_queued(job) assertion with no args passed" do
      assert_queued(JobWithArguments)
    end

    should "fail the assert_queued(job) assertion if the args don't match" do 
      assert_raise Test::Unit::AssertionFailedError do 
        assert_queued(JobWithArguments, [2, "test"])
      end
    end

    should "pass the assert_not_queued(job) assertion if the args don't match" do
      assert_not_queued(JobWithArguments, [2, "test"])
    end

    should "fail the assert_not_queued(job) assertion if the args match" do
      assert_raise Test::Unit::AssertionFailedError do 
        assert_not_queued(JobWithArguments, [1, "test"])
      end
    end

  end

end
