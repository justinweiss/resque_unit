require 'test_helper'
describe Resque do

  before do
    Resque.reset!
  end

  describe "with one queued job" do
    before do
      Resque.enqueue(MediumPriorityJob, "some args")
      @job_payload = {"args"=>["some args"], "class"=>"MediumPriorityJob"}
    end

    it "returns the job payload when peek method called with count equal 1" do
      assert_equal @job_payload, Resque.peek(MediumPriorityJob.queue, 0, 1)
    end

    it "returns an array of jobs' payloads when peek method called with count different than 1" do
      assert_equal [@job_payload], Resque.peek(MediumPriorityJob.queue, 0, 5)
    end
  end

  describe "with few queued jobs" do
    before do
      Resque.enqueue(MediumPriorityJob, "1")
      Resque.enqueue(MediumPriorityJob, "2")
      Resque.enqueue(MediumPriorityJob, "3")
    end

    it "returns jobs' payloads 2 and 3 when peek method called with start equal 1 and count equal 2" do
      assert_equal [["2"], ["3"]], Resque.peek(MediumPriorityJob.queue, 1, 2).map{|h| h["args"]}
    end

    it "returns an empty array when peek method called with start higher than queue size" do
      assert_equal [], Resque.peek(MediumPriorityJob.queue, 4, 2)
    end

    it "returns an empty array when peek method called with count equal 0" do
      assert_equal [], Resque.peek(MediumPriorityJob.queue, 0, 0)
    end

    it "returns all jobs' payloads when all method called" do
      assert Resque.all(MediumPriorityJob.queue).length == 3, "should return all 3 elements"
    end
  end

  describe "without queued jobs" do
    it "returns nil when peek method called with count equal 1" do
      assert_equal nil, Resque.peek(MediumPriorityJob.queue, 0, 1)
    end

    it "returns an empty array when peek method called with count not equal 1" do
      assert_equal [], Resque.peek(MediumPriorityJob.queue, 0, 999)
    end

    it "returns an empty array when `all` is called" do
      assert_equal [], Resque.all(MediumPriorityJob.queue)
    end
  end
end
