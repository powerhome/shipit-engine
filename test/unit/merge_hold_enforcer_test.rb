# frozen_string_literal: true

require 'test_helper'

module Shipit
  class MergeHoldEnforcerTest < ActiveSupport::TestCase
    setup do
      @stack = shipit_stacks(:shipit)
      @repository = @stack.repository
      @user = shipit_users(:walrus)
      @client = mock('octokit_client')
      @app = mock('github_app')
      @app.stubs(:api).returns(@client)
      Shipit.stubs(:github).with(organization: @repository.owner).returns(@app)
      MergeHold.where(stack: @repository.stacks).destroy_all
    end

    test "#sync! is a no-op when there are no active holds and no existing ruleset" do
      @client.expects(:get).with("/repos/#{@repository.full_name}/rulesets").returns([])
      @client.expects(:post).never
      @client.expects(:put).never
      @client.expects(:delete).never

      MergeHoldEnforcer.sync!(@repository)
    end

    test "#sync! creates a ruleset when there are active holds and none exists yet" do
      @stack.merge_holds.create!(reason: 'r', author: @user, activated_at: Time.current)

      @client.expects(:get).with("/repos/#{@repository.full_name}/rulesets").returns([])
      @client.expects(:post).with do |path, payload|
        path == "/repos/#{@repository.full_name}/rulesets" &&
          payload[:name] == Shipit.merge_hold_ruleset_name &&
          payload[:enforcement] == 'active' &&
          payload.dig(:conditions, :ref_name, :include) == ["refs/heads/#{@stack.branch}"]
      end

      MergeHoldEnforcer.sync!(@repository)
    end

    test "#sync! updates the existing ruleset when holds are still active" do
      @stack.merge_holds.create!(reason: 'r', author: @user, activated_at: Time.current)
      existing = stub(id: 42, name: Shipit.merge_hold_ruleset_name)
      @client.expects(:get).with("/repos/#{@repository.full_name}/rulesets").returns([existing])
      @client.expects(:get).with("/repos/#{@repository.full_name}/rulesets/42").returns(existing)
      @client.expects(:put).with do |path, _payload|
        path == "/repos/#{@repository.full_name}/rulesets/42"
      end

      MergeHoldEnforcer.sync!(@repository)
    end

    test "#sync! deletes the ruleset when there are no active holds" do
      existing = stub(id: 7, name: Shipit.merge_hold_ruleset_name)
      @client.expects(:get).with("/repos/#{@repository.full_name}/rulesets").returns([existing])
      @client.expects(:get).with("/repos/#{@repository.full_name}/rulesets/7").returns(existing)
      @client.expects(:delete).with("/repos/#{@repository.full_name}/rulesets/7")

      MergeHoldEnforcer.sync!(@repository)
    end

    test "#sync! includes bypass actors for exempted users" do
      hold = @stack.merge_holds.create!(reason: 'r', author: @user, activated_at: Time.current)
      hold.update!(exempt_github_logins: ['walrus'])

      @client.expects(:user).with('walrus').returns(stub(id: 12_345))
      @client.expects(:get).with("/repos/#{@repository.full_name}/rulesets").returns([])
      @client.expects(:post).with do |_path, payload|
        actor = payload[:bypass_actors].first
        actor[:actor_id] == 12_345 && actor[:actor_type] == 'Integration'
      end

      MergeHoldEnforcer.sync!(@repository)
    end
  end
end
