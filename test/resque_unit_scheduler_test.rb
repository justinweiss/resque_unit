require 'test_helper'
require 'resque_unit_scheduler'

describe Resque do
  include ResqueUnit::Assertions
  include ResqueUnit::SchedulerAssertions
  
  before do
    Resque.reset!
  end

  describe "A task that schedules a resque job in 5 minutes" do
    before { Resque.enqueue_in(600, MediumPriorityJob) }
    it "passes the assert_queued(job) assertion" do
      assert_queued(MediumPriorityJob)
    end

    it "passes the assert_queued_in(600, job) assertion" do
      assert_queued_in(600, MediumPriorityJob)
    end

    it "fails the assert_queued_in(300, job) assertion" do
      assert_raises Minitest::Assertion do
        assert_queued_in(300, MediumPriorityJob)
      end
    end

    it "passes the assert_not_queued_in(300, job) assertion" do
      assert_not_queued_in(300, MediumPriorityJob)
    end

    describe "and then the job is removed with #remove_delayed" do
      before do
        Resque.remove_delayed(MediumPriorityJob)
      end
      it "passes the assert_not_queued_at(@time, MediumPriorityJob) assertion" do
        assert_not_queued_at(300, MediumPriorityJob)
      end

      it "fails the assert_queued_at(@time, MediumPriorityJob) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(300, MediumPriorityJob)
        end
      end
    end
  end

  describe "A task that schedules a resque job in 5 minutes with arguments" do
    before { Resque.enqueue_in(600, JobWithArguments, 1, "test") }
    it "passes the assert_queued_in(600, JobWithArguments) assertion" do
      assert_queued_in(600, JobWithArguments)
    end

    it "passes the assert_queued_in(600, JobWithArguments, [1, 'test']) assertion" do
      assert_queued_in(600, JobWithArguments, [1, 'test'])
    end

    it "fails the assert_queued_in(600, JobWithArguments, [2, 'test']) assertion" do
      assert_raises Minitest::Assertion do
        assert_queued_in(600, JobWithArguments, [2, 'test'])
      end
    end

    describe "and then the job is removed with #remove_delayed" do
      before do
        Resque.remove_delayed(JobWithArguments, 1, 'test')
      end
      it "passes the assert_not_queued_at(@time, JobWithArguments, 1, 'test') assertion" do
        assert_not_queued_at(600, JobWithArguments, 1, 'test')
      end

      it "fails the assert_queued_at(@time, JobWithArguments, 1, 'test') assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(600, JobWithArguments, 1, 'test')
        end
      end
    end

    describe "and a job of the same class but with different arguments is removed with #remove_delayed" do
      before do
        Resque.remove_delayed(JobWithArguments, 2, 'test')
      end
      it "still passes the assert_queued_in(600, JobWithArguments) assertion" do
        assert_queued_in(600, JobWithArguments)
      end

      it "still passes the assert_queued_in(600, JobWithArguments, [1, 'test']) assertion" do
        assert_queued_in(600, JobWithArguments, [1, 'test'])
      end

      it "still fails the assert_queued_in(600, JobWithArguments, [2, 'test']) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_in(600, JobWithArguments, [2, 'test'])
        end
      end
    end
  end

  describe "A task that schedules a resque job on Sept. 6, 2016 at 6am" do
    before do
      @time = Time.mktime(2016, 9, 6, 6)
      Resque.enqueue_at(@time, MediumPriorityJob)
    end

    it "passes the assert_queued_at(@time, MediumPriorityJob) assertion" do
      assert_queued_at(@time, MediumPriorityJob)
    end

    it "fails the assert_queued_at(@time - 100, MediumPriorityJob) assertion" do
      assert_raises Minitest::Assertion do
        assert_queued_at(@time - 100, MediumPriorityJob)
      end
    end

    it "passes the assert_not_queued_at(@time - 100, MediumPriorityJob) assertion" do
      assert_not_queued_at(@time - 100, MediumPriorityJob)
    end

    describe "and then the job is removed with #remove_delayed" do
      before do
        Resque.remove_delayed(MediumPriorityJob)
      end
      it "passes the assert_not_queued_at(@time, MediumPriorityJob) assertion" do
        assert_not_queued_at(@time, MediumPriorityJob)
      end

      it "fails the assert_queued_at(@time, MediumPriorityJob) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(@time, MediumPriorityJob)
        end
      end
    end

    describe "and then the job is removed with #remove_delayed_job_from_timestamp" do
      before do
        Resque.remove_delayed_job_from_timestamp(@time, MediumPriorityJob)
      end

      it "passes the assert_not_queued_at(@time, MediumPriorityJob) assertion" do
        assert_not_queued_at(@time, MediumPriorityJob)
      end

      it "fails the assert_queued_at(@time, MediumPriorityJob) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(@time, MediumPriorityJob)
        end
      end
    end

    describe "and then the job is removed with #remove_delayed_job_from_timestamp with timestamp specified in another timezone" do
      before do
        Resque.remove_delayed_job_from_timestamp(@time.utc, MediumPriorityJob)
      end

      it "passes the assert_not_queued_at(@time, MediumPriorityJob) assertion" do
        assert_not_queued_at(@time, MediumPriorityJob)
      end

      it "fails the assert_queued_at(@time, MediumPriorityJob) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(@time, MediumPriorityJob)
        end
      end
    end
  end

  describe "A task that schedules a resque job with arguments on on Sept. 6, 2016 at 6am" do
    before do
      @time = Time.mktime(2016, 9, 6, 6)
      Resque.enqueue_at(@time, JobWithArguments, 1, "test")
    end

    it "passes the assert_queued_at(@time, JobWithArguments, *args) assertion" do
      assert_queued_at(@time, JobWithArguments, [1, "test"])
    end

    it "fails the assert_queued_at(@time - 100, JobWithArguments, *args) assertion" do
      assert_raises Minitest::Assertion do
        assert_queued_at(@time - 100, JobWithArguments, [1, "test"])
      end
    end

    it "passes the assert_not_queued_at(@time - 100, JobWithArguments, *args) assertion" do
      assert_not_queued_at(@time - 100, JobWithArguments, [1, "test"])
    end

    describe "and then the job is removed with #remove_delayed" do
      before do
        Resque.remove_delayed(JobWithArguments, 1, "test")
      end

      it "passes the assert_not_queued_at(@time, JobWithArguments, *args) assertion" do
        assert_not_queued_at(@time, JobWithArguments, [1, "test"])
      end

      it "fails the assert_queued_at(@time, JobWithArguments, *args) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(@time, JobWithArguments, [1, "test"])
        end
      end
    end

    describe "and then the job is removed with #remove_delayed_job_from_timestamp" do
      before do
        Resque.remove_delayed_job_from_timestamp(@time, JobWithArguments, 1, "test")
      end

      it "pass the assert_not_queued_at(@time, JobWithArguments, *args) assertion" do
        assert_not_queued_at(@time, JobWithArguments, [1, "test"])
      end

      it "fail the assert_queued_at(@time, MediumPriorityJob, *args) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(@time, JobWithArguments, [1, "test"])
        end
      end
    end

    describe "and then the job is removed with #remove_delayed_job_from_timestamp with timestamp in another timezone" do
      before do
        Resque.remove_delayed_job_from_timestamp(@time.utc, JobWithArguments, 1, "test")
      end

      it "passes the assert_not_queued_at(@time, JobWithArguments, *args) assertion" do
        assert_not_queued_at(@time, JobWithArguments, [1, "test"])
      end

      it "fails the assert_queued_at(@time, MediumPriorityJob, *args) assertion" do
        assert_raises Minitest::Assertion do
          assert_queued_at(@time, JobWithArguments, [1, "test"])
        end
      end
    end
  end
end
