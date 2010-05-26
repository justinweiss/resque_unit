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
  end

end
