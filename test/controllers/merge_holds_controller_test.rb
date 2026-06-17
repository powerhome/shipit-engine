# frozen_string_literal: true

require 'test_helper'

module Shipit
  class MergeHoldsControllerTest < ActionController::TestCase
    setup do
      @routes = Shipit::Engine.routes
      @stack = shipit_stacks(:shipit)
      session[:user_id] = shipit_users(:walrus).id
    end

    test "#index shows the stack's merge holds" do
      get :index, params: { stack_id: @stack.to_param }
      assert_response(:success)
    end

    test "#new renders a new merge hold form" do
      get :new, params: { stack_id: @stack.to_param }
      assert_response(:success)
    end

    test "#show renders an existing merge hold" do
      hold = shipit_merge_holds(:shipit_active)
      get :show, params: { stack_id: @stack.to_param, id: hold.id }
      assert_response(:success)
    end

    test "#create creates a new merge hold and redirects to the index" do
      assert_difference -> { MergeHold.count }, +1 do
        post :create, params: {
          stack_id: @stack.to_param,
          merge_hold: { reason: 'Deploying carefully', starts_at: '', ends_at: '' }
        }
      end
      assert_redirected_to(stack_merge_holds_path(@stack))
      assert_equal('Merge hold created', flash[:success])
    end

    test "#create renders new on invalid params" do
      assert_no_difference -> { MergeHold.count } do
        post :create, params: {
          stack_id: @stack.to_param,
          merge_hold: { reason: '', starts_at: '', ends_at: '' }
        }
      end
      assert_response(:unprocessable_entity)
    end

    test "#revoke revokes the merge hold and redirects" do
      hold = shipit_merge_holds(:shipit_active)
      post :revoke, params: { stack_id: @stack.to_param, id: hold.id }
      assert_redirected_to(stack_merge_holds_path(@stack))
      assert_predicate(hold.reload, :revoked?)
    end

    test "#revoke flashes warning if hold cannot be revoked" do
      hold = shipit_merge_holds(:shipit_revoked)
      post :revoke, params: { stack_id: @stack.to_param, id: hold.id }
      assert_redirected_to(stack_merge_holds_path(@stack))
      assert_equal('Could not revoke merge hold', flash[:warning])
    end

    test "#global_index renders active holds across all stacks" do
      get :global_index
      assert_response(:success)
    end
  end
end
