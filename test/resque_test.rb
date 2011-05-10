require 'test_helper'

class ResqueTest < Test::Unit::TestCase

  def setup
    Resque.reset!
  end

  context "with one queued job" do
    setup do
      Resque.enqueue(MediumPriorityJob, "some args")
      @job_payload = {:args=>["some args"], :klass=>MediumPriorityJob}
    end

    should "return job payload if peek method called with count equal 1" do
      assert_equal Resque.peek(MediumPriorityJob.queue, 0, 1), @job_payload
    end

    should "return array of jobs' payloads if peek method called with count different than 1" do
      assert_equal Resque.peek(MediumPriorityJob.queue, 0, 5), [@job_payload]
    end
  end

  context "with few queued jobs" do
    setup do
      Resque.enqueue(MediumPriorityJob, "1")
      Resque.enqueue(MediumPriorityJob, "2")
      Resque.enqueue(MediumPriorityJob, "3")
    end

    should "return jobs' payloads 2 and 3 if start is set to 1 and count equal 2" do
      assert_equal Resque.peek(MediumPriorityJob.queue, 1, 2).map{|h| h[:args]}, [["2"], ["3"]]
    end

    should "return empty array if start is higher than queue size" do
      assert_equal Resque.peek(MediumPriorityJob.queue, 4, 2), []
    end

    should "return empty array if count is equal 0" do
      assert_equal Resque.peek(MediumPriorityJob.queue, 0, 0), []
    end
  end

  context "without queued jobs" do
    should "return nil if count is 1" do
      assert_equal Resque.peek(MediumPriorityJob.queue, 0, 1), nil
    end

    should "return empty array if count is not 1" do
      assert_equal Resque.peek(MediumPriorityJob.queue, 0, 999), []
    end
  end
end
