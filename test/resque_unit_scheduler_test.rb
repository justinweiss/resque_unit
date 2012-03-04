require 'test_helper'
require 'resque_unit_scheduler'

class ResqueUnitSchedulerTest < Test::Unit::TestCase

  def setup
    Resque.reset!
  end

  context "A task that schedules a resque job in 5 minutes" do
    setup { Resque.enqueue_in(600, MediumPriorityJob) }
    should "pass the assert_queued(job) assertion" do
      assert_queued(MediumPriorityJob)
    end

    should "pass the assert_queued_in(600, job) assertion" do
      assert_queued_in(600, MediumPriorityJob)
    end

    should "fail the assert_queued_in(300, job) assertion" do
      assert_raise Test::Unit::AssertionFailedError do 
        assert_queued_in(300, MediumPriorityJob)
      end
    end

    should "pass the assert_not_queued_in(300, job) assertion" do 
      assert_not_queued_in(300, MediumPriorityJob)
    end

    context "and then the job is removed with #remove_delayed" do
      setup do
        Resque.remove_delayed(MediumPriorityJob)
      end
      should "pass the assert_not_queued_at(@time, MediumPriorityJob) assertion" do 
        assert_not_queued_at(300, MediumPriorityJob)
      end

      should "fail the assert_queued_at(@time, MediumPriorityJob) assertion" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_queued_at(300, MediumPriorityJob)
        end
      end
    end
  end
  
  context "A task that schedules a resque job in 5 minutes with arguments" do
    setup { Resque.enqueue_in(600, JobWithArguments, 1, "test") }
    should "pass the assert_queued_in(600, JobWithArguments) assertion" do
      assert_queued_in(600, JobWithArguments)
    end

    should "pass the assert_queued_in(600, JobWithArguments, [1, 'test']) assertion" do
      assert_queued_in(600, JobWithArguments, [1, 'test'])
    end

    should "fail the assert_queued_in(600, JobWithArguments, [2, 'test']) assertion" do 
      assert_raise Test::Unit::AssertionFailedError do 
        assert_queued_in(600, JobWithArguments, [2, 'test'])
      end
    end

    context "and then the job is removed with #remove_delayed" do
      setup do
        Resque.remove_delayed(JobWithArguments, 1, 'test')
      end
      should "pass the assert_not_queued_at(@time, JobWithArguments, 1, 'test') assertion" do 
        assert_not_queued_at(600, JobWithArguments, 1, 'test')
      end

      should "fail the assert_queued_at(@time, JobWithArguments, 1, 'test') assertion" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_queued_at(600, JobWithArguments, 1, 'test')
        end
      end
    end

    context "and a job of the same class but with different arguments is removed with #remove_delayed" do
      setup do
        Resque.remove_delayed(JobWithArguments, 2, 'test')
      end
      should "still pass the assert_queued_in(600, JobWithArguments) assertion" do
        assert_queued_in(600, JobWithArguments)
      end

      should "still pass the assert_queued_in(600, JobWithArguments, [1, 'test']) assertion" do
        assert_queued_in(600, JobWithArguments, [1, 'test'])
      end

      should "still fail the assert_queued_in(600, JobWithArguments, [2, 'test']) assertion" do 
        assert_raise Test::Unit::AssertionFailedError do 
          assert_queued_in(600, JobWithArguments, [2, 'test'])
        end
      end
    end
  end
    
  context "A task that schedules a resque job on Sept. 6, 2016 at 6am" do
    setup do
      @time = Time.mktime(2016, 9, 6, 6)
      Resque.enqueue_at(@time, MediumPriorityJob)
    end

    should "pass the assert_queued_at(@time, MediumPriorityJob) assertion" do 
      assert_queued_at(@time, MediumPriorityJob)
    end

    should "fail the assert_queued_at(@time - 100, MediumPriorityJob) assertion" do 
      assert_raise Test::Unit::AssertionFailedError do 
        assert_queued_at(@time - 100, MediumPriorityJob)
      end
    end

    should "pass the assert_not_queued_at(@time - 100, MediumPriorityJob) assertion" do
      assert_not_queued_at(@time - 100, MediumPriorityJob)
    end

    context "and then the job is removed with #remove_delayed" do
      setup do
        Resque.remove_delayed(MediumPriorityJob)
      end
      should "pass the assert_not_queued_at(@time, MediumPriorityJob) assertion" do 
        assert_not_queued_at(@time, MediumPriorityJob)
      end

      should "fail the assert_queued_at(@time, MediumPriorityJob) assertion" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_queued_at(@time, MediumPriorityJob)
        end
      end
    end

    context "and then the job is removed with #remove_delayed_job_with_timestamp" do
      setup do
        Resque.remove_delayed_job_from_timestamp(@time, MediumPriorityJob)
      end

      should "pass the assert_not_queued_at(@time, MediumPriorityJob) assertion" do
        assert_not_queued_at(@time, MediumPriorityJob)
      end

      should "fail the assert_queued_at(@time, MediumPriorityJob) assertion" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_queued_at(@time, MediumPriorityJob)
        end
      end
    end
  end

  context "A task that schedules a resque job with arguments on on Sept. 6, 2016 at 6am" do
    setup do
      @time = Time.mktime(2016, 9, 6, 6)
      Resque.enqueue_at(@time, JobWithArguments, 1, "test")
    end

    should "pass the assert_queued_at(@time, JobWithArguments, *args) assertion" do
      assert_queued_at(@time, JobWithArguments, 1, "test")
    end

    should "fail the assert_queued_at(@time - 100, JobWithArguments, *args) assertion" do
      assert_raise Test::Unit::AssertionFailedError do
        assert_queued_at(@time - 100, JobWithArguments, 1, "test")
      end
    end

    should "pass the assert_not_queued_at(@time - 100, JobWithArguments, *args) assertion" do
      assert_not_queued_at(@time - 100, JobWithArguments, 1, "test")
    end

    context "and then the job is removed with #remove_delayed" do
      setup do
        Resque.remove_delayed(JobWithArguments, 1, "test")
      end

      should "pass the assert_not_queued_at(@time, JobWithArguments, *args) assertion" do
        assert_not_queued_at(@time, JobWithArguments, 1, "test")
      end

      should "fail the assert_queued_at(@time, JobWithArguments, *args) assertion" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_queued_at(@time, JobWithArguments, 1, "test")
        end
      end
    end

    context "and then the job is removed with #remove_delayed_job_with_timestamp" do
      setup do
        Resque.remove_delayed_job_from_timestamp(@time, JobWithArguments, 1, "test")
      end

      should "pass the assert_not_queued_at(@time, JobWithArguments, *args) assertion" do
        assert_not_queued_at(@time, JobWithArguments, 1, "test")
      end

      should "fail the assert_queued_at(@time, MediumPriorityJob, *args) assertion" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_queued_at(@time, JobWithArguments, 1, "test")
        end
      end
    end
  end
end
