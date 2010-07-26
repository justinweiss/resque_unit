require 'test_helper'

class ResqueUnitTest < Test::Unit::TestCase

  def setup
    # should probably happen automatically, but I haven't thought of a
    # good way to hook setup() yet.
    Resque.reset!
  end

  context "A task that schedules a resque job implementing self.queue" do
    setup { Resque.enqueue(MediumPriorityJob) }
    should "pass the assert_queued(job) assertion" do
      assert_queued(MediumPriorityJob)
      assert_equal 1, Resque.queue(MediumPriorityJob.queue).length
    end
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

    should "should be size 1" do
      assert_equal 1, Resque.size(:low)
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

      should "clear the job from the queue" do
        assert_not_queued(LowPriorityJob)
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

    should "be size 0 when empty" do
      assert_equal 0, Resque.size(:low)
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

  context "A job that schedules a new resque job" do
    setup do 
      Resque.enqueue(JobThatCreatesANewJob)
    end

    should "pass the assert_queued(job) assertion" do 
      assert_queued(JobThatCreatesANewJob)
    end

    should "fail the assert_not_queued(job) assertion" do 
      assert_raise Test::Unit::AssertionFailedError do 
        assert_not_queued(JobThatCreatesANewJob)
      end
    end

    should "pass the assert_not_queued(LowPriorityJob) assertion" do
      assert_not_queued(LowPriorityJob)
    end

    context ", when Resque.run! is called," do 
      setup do 
        Resque.run!
      end

      should "clear the job from the queue" do
        assert_not_queued(JobThatCreatesANewJob)
      end

      should "add a LowPriorityJob" do
        assert_queued(LowPriorityJob)
      end
    end
  end

  context "An assertion message" do
    context "of assert_queued" do
      should "include job class and queue content" do
        begin
          assert_queued(LowPriorityJob)
        rescue Test::Unit::AssertionFailedError => error
          assert_equal "LowPriorityJob should have been queued in low: [].", error.message
        end
      end
      
      should "include job arguments if provided" do
        begin
          assert_queued(JobWithArguments, [1, "test"])
        rescue Test::Unit::AssertionFailedError => error
          assert_equal "JobWithArguments with [1, \"test\"] should have been queued in medium: [].", error.message
        end
      end
    end

    # TODO: of assert_not_queued
  end
end
