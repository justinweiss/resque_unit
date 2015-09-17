require 'test_helper'

describe ResqueUnit do

  before do
    # should probably happen automatically, but I haven't thought of a
    # good way to hook setup() yet.
    Resque.reset!
  end

  describe "A task that schedules a resque job implementing self.queue" do
    before { Resque.enqueue(MediumPriorityJob) }
    it "passes the assert_queued(job) assertion" do
      assert_queued(MediumPriorityJob)
      assert_job_created(MediumPriorityJob.queue, MediumPriorityJob)
      assert_equal 1, Resque.queue(MediumPriorityJob.queue).length
    end
  end

  describe "A task that explicitly is queued to a different queue" do
    before { Resque.enqueue_to(:a_non_class_determined_queue, MediumPriorityJob) }
    it "does not queue to the class-determined queue" do
      assert_equal 0, Resque.queue(MediumPriorityJob.queue).length
    end
    it "queues to the explicly-stated queue" do
      assert_equal 1, Resque.queue(:a_non_class_determined_queue).length
    end
  end

  describe "A task that spawns multiple jobs on a single queue" do
    before do
      3.times {Resque.enqueue(HighPriorityJob)}
    end

    it "allows partial runs with explicit limit" do
      assert_equal 3, Resque.queue(:high).length, 'failed setup'
      Resque.run_for!( :high, 1 )
      assert_equal 2, Resque.queue(:high).length, 'failed to run just single job'
    end

    it "allows full run with too-large explicit limit" do
      assert_equal 3, Resque.queue(:high).length, 'failed setup'
      Resque.run_for!( :high, 50 )
      assert_equal 0, Resque.queue(:high).length, 'failed to run all jobs'
    end

    it "allows full run with implicit limit" do
      assert_equal 3, Resque.queue(:high).length, 'failed setup'
      Resque.run_for!( :high )
      assert_equal 0, Resque.queue(:high).length, 'failed to run all jobs'
    end
  end

  describe "A task that schedules a resque job" do
    before do
      @returned = Resque.enqueue(LowPriorityJob)
    end

    it 'returns a value that evaluates to true' do
      assert @returned
    end

    it "passes the assert_queued(job) assertion" do
      assert_queued(LowPriorityJob)
    end

    it "fails the assert_not_queued(job) assertion" do
      assert_raises Minitest::Assertion do
        assert_not_queued(LowPriorityJob)
      end
    end

    it "has 1 job in the queue" do
      assert_equal 1, Resque.size(:low)
    end

    describe ", when Resque.run! is called," do
      before do
        assert !LowPriorityJob.run?, "The job should not have been run yet"
        Resque.run!
      end

      after do
        LowPriorityJob.run = false
      end

      it "runs the job" do
        assert LowPriorityJob.run?, "The job should have run"
      end

      it "clears the job from the queue" do
        assert_not_queued(LowPriorityJob)
      end
    end

    # assert number of jobs?
  end

  describe "A task that schedules a resque job with hooks" do
    before do
      Resque.enable_hooks!
    end

    after do
      Resque.disable_hooks!
    end

    describe "before, around, after, failure, after_enqueue" do
      before do
        JobWithHooks.clear_markers
        Resque.enqueue(JobWithHooks)
      end

      it "ran the after_enqueue hook" do
        assert_queued(JobWithHooks)
        assert(JobWithHooks.markers[:after_enqueue], 'no after_queue marker set')
      end

      it "ran the before_enqueue hook" do
        assert(JobWithHooks.markers[:before_enqueue], 'no before_queue marker set')
        assert_queued(JobWithHooks)
      end

      it "ran the before and after hooks during a run" do
        Resque.run!
        assert(JobWithHooks.markers[:before], 'no before marker set')
        assert(JobWithHooks.markers[:around], 'no around marker set')
        assert(JobWithHooks.markers[:after], 'no after marker set')
        assert(!JobWithHooks.markers[:failed], 'failed marker set, and it should not')
      end

      it "ran the before and failed hooks during a run" do
        JobWithHooks.make_it_fail do
          assert_raises(RuntimeError) do
            Resque.run!
            assert(JobWithHooks.markers[:before], 'no before marker set')
            assert(JobWithHooks.markers[:around], 'no around marker set')
            assert(!JobWithHooks.markers[:after], 'after marker set, and it should not')
            assert(JobWithHooks.markers[:failed], 'no failed marker set')
          end
        end
      end

      it "does not call perform if the around hook raised Resque::Job::DontPerform" do
        JobWithHooks.make_it_dont_perform do
          Resque.run!
          assert(JobWithHooks.markers[:before], 'no before marker set')
          assert(JobWithHooks.markers[:around], 'no around marker set')
          assert(!JobWithHooks.markers[:after], 'after marker set, and it should not')
          assert(!JobWithHooks.markers[:failed], 'failed marker set, and it should not')
        end
      end
    end

    describe "but without before" do
      before do
        JobWithHooksWithoutBefore.clear_markers
        Resque.enqueue(JobWithHooksWithoutBefore)
      end

      it "does not run before hooks during a run" do
        Resque.run!
        assert(!JobWithHooksWithoutBefore.markers[:before], 'before marker set, and it should not')
      end
    end

    describe "when before_enqueue returns false" do
      before do
        JobWithHooksBeforeBlocks.clear_markers
      end

      it "does not queue" do
        Resque.enqueue JobWithHooksBeforeBlocks
        assert_not_queued JobWithHooksBeforeBlocks
      end

    end

    describe "but without around" do
      before do
        JobWithHooksWithoutAround.clear_markers
        Resque.enqueue(JobWithHooksWithoutAround)
      end

      it "does not run around hooks during a run" do
        Resque.run!
        assert(!JobWithHooksWithoutAround.markers[:around], 'around marker set, and it should not')
      end
    end
  end

  describe "Block assertions" do
    it "passes the assert_queued(job) assertion when queued in block" do
      assert_queues(HighPriorityJob) do
        Resque.enqueue(HighPriorityJob)
      end
    end

    it "passes the assert_queued(job) assertion when queued in block and outside" do
      Resque.enqueue(HighPriorityJob)
      assert_queues(HighPriorityJob) do
        Resque.enqueue(HighPriorityJob)
      end
    end

    it "fails the assert_queued(job) assertion when not queued in block but outside" do
      Resque.enqueue(LowPriorityJob)
      assert_raises Minitest::Assertion do
        assert_queues(LowPriorityJob) do
          # Nothing.
        end
      end
    end

    it "passes the assert_not_queued(job) assertion when not queued in block" do
      Resque.enqueue(LowPriorityJob)
      assert_not_queued(LowPriorityJob) do
        # Nothing.
      end
    end

    it "fails the assert_not_queued(job) assertion when not queued in block" do
      assert_raises Minitest::Assertion do
        assert_not_queued(LowPriorityJob) do
          Resque.enqueue(LowPriorityJob)
        end
      end
    end

    it "fails the assert_not_queued(job) assertion when queued and not in block" do
      assert_raises Minitest::Assertion do
        Resque.enqueue(LowPriorityJob)
        assert_not_queued(LowPriorityJob) do
          Resque.enqueue(LowPriorityJob)
        end
      end
    end

    it "passes the assert_nothing_queued assertion when nothing queued in block" do
      Resque.enqueue(LowPriorityJob)
      assert_nothing_queued do
        # Nothing.
      end
    end

    it "fails the assert_nothing_queued assertion when queued in block" do
      assert_raises Minitest::Assertion do
        assert_nothing_queued do
          Resque.enqueue(LowPriorityJob)
        end
      end
    end
  end

  describe "An empty queue" do
    it "passes the assert_not_queued(job) assertion" do
      assert_not_queued(LowPriorityJob)
    end

    it "fails the assert_queued(job) assertion" do
      assert_raises Minitest::Assertion do
        assert_queued(LowPriorityJob)
      end
    end

    it "is size 0 when empty" do
      assert_equal 0, Resque.size(:low)
    end
  end

  describe "A task that schedules a resque job with arguments" do
    before do
      Resque.enqueue(JobWithArguments, 1, :test, {:symbol => :symbol})
    end

    it "passes the assert_queued(job, *args) assertion if the args match and sees enqueued symbols as strings" do
      assert_queued(JobWithArguments, [1, "test", {"symbol"=>"symbol"}])
    end

    it "passes the assert_queued(job, *args) assertion if the args match using symbols" do
      assert_queued(JobWithArguments, [1, :test, {:symbol => :symbol}])
    end

    it "passes the assert_queued(job) assertion with no args passed" do
      assert_queued(JobWithArguments)
    end

    it "fails the assert_queued(job) assertion if the args don't match" do
      assert_raises Minitest::Assertion do
        assert_queued(JobWithArguments, [2, "test"])
      end
    end

    it "passes the assert_not_queued(job) assertion if the args don't match" do
      assert_not_queued(JobWithArguments, [2, "test"])
    end

    it "fails the assert_not_queued(job) assertion if the args match" do
      assert_raises Minitest::Assertion do
        assert_not_queued(JobWithArguments, [1, "test", {"symbol"=>"symbol"}])
      end
    end
  end

  describe "A job that schedules a new resque job" do
    before do
      Resque.enqueue(JobThatCreatesANewJob)
    end

    it "passes the assert_queued(job) assertion" do
      assert_queued(JobThatCreatesANewJob)
    end

    it "fails the assert_not_queued(job) assertion" do
      assert_raises Minitest::Assertion do
        assert_not_queued(JobThatCreatesANewJob)
      end
    end

    it "passes the assert_not_queued(LowPriorityJob) assertion" do
      assert_not_queued(LowPriorityJob)
    end

    describe ", when Resque.run! is called," do
      before do
        Resque.run!
      end

      it "clears the job from the queue" do
        assert_not_queued(JobThatCreatesANewJob)
      end

      it "adds a LowPriorityJob" do
        assert_queued(LowPriorityJob)
      end
    end

    describe ", when Resque.full_run!" do
      before do
        assert !LowPriorityJob.run?, "The job should not have run yet, did you call 'LowPriorityJob.run = false' in teardowns of other tests?"
        Resque.full_run!
      end

      after do
        LowPriorityJob.run = false
      end

      it "clears the jobs from the queue" do
        assert_not_queued(JobThatCreatesANewJob)
        assert_not_queued(LowPriorityJob)
      end

      it "runs the new resque jobs" do
        assert LowPriorityJob.run?, "LowPriorityJob should have been run"
      end
    end
  end

  describe "A task in a different queue" do
    before do
      Resque.enqueue(LowPriorityJob)
      Resque.enqueue(HighPriorityJob)
    end

    it "adds a LowPriorityJob" do
      assert_queued(LowPriorityJob)
    end

    it "adds a HighPriorityJob" do
      assert_queued(HighPriorityJob)
    end

    describe ", when Resque.run_for! is called," do
      it "runs only tasks in the high priority queue" do
        Resque.run_for!(Resque.queue_for(HighPriorityJob))

        assert_queued(LowPriorityJob)
        assert_not_queued(HighPriorityJob)
      end
    end
  end

  describe "An assertion message" do
    describe "of assert_queued" do
      it "includes job class and queue content" do
        begin
          assert_not_queued(LowPriorityJob)
        rescue Minitest::Assertion => error
          assert_equal "LowPriorityJob should have been queued in low: [].", error.message
        end
      end

      it "includes job arguments if provided" do
        begin
          assert_not_queued(JobWithArguments, [1, "test"])
        rescue Minitest::Assertion => error
          assert_equal "JobWithArguments with [1, \"test\"] should have been queued in medium: [].", error.message
        end
      end
    end

    describe "of assert_not_queued" do
      it "includes job class and queue content" do
        begin
          Resque.enqueue(LowPriorityJob)
          assert_not_queued(LowPriorityJob)
        rescue Minitest::Assertion => error
          assert_equal "LowPriorityJob should not have been queued in low.", error.message
        end
      end

      it "includes job arguments if provided" do
        begin
          Resque.enqueue(JobWithArguments, 1, "test")
          assert_not_queued(JobWithArguments, [1, "test"])
        rescue Minitest::Assertion => error
          assert_equal "JobWithArguments with [1, \"test\"] should not have been queued in medium.", error.message
        end
      end
    end

    describe "of assert_nothing_queued" do
      it "includes diff" do
        begin
          Resque.reset!
          assert_nothing_queued do
            Resque.enqueue(LowPriorityJob)
          end
        rescue Minitest::Assertion => error
          assert_equal "No jobs should have been queued.\nExpected: 0\n  Actual: 1", error.message
        end
      end
    end
  end

  describe "A job that does not specify a queue" do
    it "receives Resque::NoQueueError" do
      assert_raises(Resque::NoQueueError) do
        Resque.enqueue(JobThatDoesNotSpecifyAQueue)
      end
    end
  end

  describe "A job that is created using Resque::Job.create" do
    it "is queued" do
      Resque::Job.create(:my_custom_queue, "LowPriorityJob", "arg1", "arg2")
      assert_job_created(:my_custom_queue, LowPriorityJob, ["arg1", "arg2"])
    end

    it "queues a job with a dasherized name" do
      Resque::Job.create(:my_custom_queue, "low-priority-job", "arg1", "arg2")
      assert_job_created(:my_custom_queue, LowPriorityJob, ["arg1", "arg2"])
    end
  end

end
