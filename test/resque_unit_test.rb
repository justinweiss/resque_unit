require 'test_helper'

class ResqueUnitTest < ActiveSupport::TestCase

  context "A task that schedules a resque job" do
    setup do 
      Resque.enqueue(LowPriorityJob)
    end

    should "pass the assert_queued(job) assertion" do 
      assert_queued(LowPriorityJob)
    end

    # assert number of jobs?
    # assert not queued
    # assert queue name
  end

end
