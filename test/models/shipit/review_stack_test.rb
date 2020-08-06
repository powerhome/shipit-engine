# frozen_string_literal: true

require 'test_helper'

module Shipit
  class ReviewStackTest < ActiveSupport::TestCase
    setup do
      @stack = shipit_stacks(:review_stack)
    end

    test ".review_request is nil by default" do
      assert_nil @stack.review_request
    end

    test ".review_request returns nil when all pull requests are merge requests" do
      assert_nil @stack.review_request
    end

    test ".review_request returns latest non merge request" do
      @pull_request = PullRequest.create!(stack: @stack, number: "1", review_request: true)

      assert @stack.review_request, @pull_request
    end

    test "clearing stale caches" do
      # Asserting that :archived_25hours_ago, :archived_30minutes_ago and :shipit are not queued.
      assert_enqueued_jobs 1 do
        assert_enqueued_with(job: Shipit::ClearGitCacheJob, args: [shipit_stacks(:archived_6hours_ago)]) do
          ReviewStack.clear_stale_caches
        end
      end
    end

    test ".enqueue_for_provisioning locks deployments" do
      assert_changes -> { @stack.locked? }, from: false, to: true do
        assert_changes -> { @stack.lock_reason_code }, from: nil, to: ReviewStack::AWAITING_PROVISIONING_LOCK_REASON_CODE do
          @stack.enqueue_for_provisioning
        end
      end
    end

    test ".remove_from_provisioning_queue removes locks deployments" do
      @stack.update!(
        lock_reason: ReviewStack::AWAITING_PROVISIONING_LOCK_REASON,
        lock_reason_code: ReviewStack::AWAITING_PROVISIONING_LOCK_REASON_CODE
      )
      assert_changes -> { @stack.locked? }, from: true, to: false do
        assert_changes -> { @stack.lock_reason_code }, from: ReviewStack::AWAITING_PROVISIONING_LOCK_REASON_CODE, to: nil do
          @stack.remove_from_provisioning_queue
        end
      end
    end
  end
end
