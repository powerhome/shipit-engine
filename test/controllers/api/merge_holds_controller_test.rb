# frozen_string_literal: true

require 'test_helper'

module Shipit
  module Api
    class MergeHoldsControllerTest < ApiControllerTestCase
      setup do
        authenticate!
        @stack = shipit_stacks(:shipit)
        @hold = shipit_merge_holds(:shipit_active)
      end

      test "#index returns merge holds for the stack" do
        get :index, params: { stack_id: @stack.to_param }
        assert_response(:ok)
      end

      test "#global_index returns active merge holds across all stacks" do
        get :global_index
        assert_response(:ok)
      end

      test "#show returns a merge hold" do
        get :show, params: { stack_id: @stack.to_param, id: @hold.id }
        assert_response(:ok)
        assert_json('id', @hold.id)
      end

      test "#create creates a merge hold" do
        assert_difference -> { MergeHold.count }, +1 do
          post :create, params: { stack_id: @stack.to_param, reason: 'Hold for testing' }
        end
        assert_response(:created)
        assert_json('reason', 'Hold for testing')
      end

      test "#create returns unprocessable_entity without a reason" do
        post :create, params: { stack_id: @stack.to_param }
        assert_response(:unprocessable_entity)
      end

      test "#create accepts exempt_github_logins" do
        post :create, params: {
          stack_id: @stack.to_param,
          reason: 'r',
          exempt_github_logins: %w[walrus bot]
        }
        assert_response(:created)
        hold = MergeHold.last
        assert_equal(%w[walrus bot].sort, hold.exempt_github_logins.sort)
      end

      test "#revoke revokes a merge hold" do
        post :revoke, params: { stack_id: @stack.to_param, id: @hold.id }
        assert_response(:ok)
        assert_predicate(@hold.reload, :revoked?)
      end

      test "#revoke returns conflict if already revoked" do
        revoked = shipit_merge_holds(:shipit_revoked)
        post :revoke, params: { stack_id: @stack.to_param, id: revoked.id }
        assert_response(:conflict)
      end
    end
  end
end
