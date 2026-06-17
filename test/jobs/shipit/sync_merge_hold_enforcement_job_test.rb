# frozen_string_literal: true

require 'test_helper'

module Shipit
  class SyncMergeHoldEnforcementJobTest < ActiveSupport::TestCase
    setup do
      @repository = shipit_repositories(:shipit)
    end

    test "#perform calls MergeHoldEnforcer.sync!" do
      MergeHoldEnforcer.expects(:sync!).with(@repository).once
      SyncMergeHoldEnforcementJob.new.perform(@repository)
    end

    test "#perform is a no-op without a repository" do
      MergeHoldEnforcer.expects(:sync!).never
      SyncMergeHoldEnforcementJob.new.perform(nil)
    end
  end
end
