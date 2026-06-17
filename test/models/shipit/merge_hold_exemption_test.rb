# frozen_string_literal: true

require 'test_helper'

module Shipit
  class MergeHoldExemptionTest < ActiveSupport::TestCase
    setup do
      @hold = shipit_merge_holds(:shipit_active)
    end

    test "requires a github_login" do
      exemption = MergeHoldExemption.new(merge_hold: @hold, github_login: '')
      refute_predicate(exemption, :valid?)
      assert_includes(exemption.errors[:github_login], "can't be blank")
    end

    test "requires github_login to be unique per merge_hold" do
      exemption = MergeHoldExemption.new(merge_hold: @hold, github_login: 'walrus')
      refute_predicate(exemption, :valid?)
      assert_includes(exemption.errors[:github_login], 'has already been taken')
    end

    test "strips whitespace from github_login" do
      exemption = MergeHoldExemption.create!(merge_hold: @hold, github_login: '  fluffy  ')
      assert_equal('fluffy', exemption.github_login)
    end

    test "strips leading @ from github_login" do
      exemption = MergeHoldExemption.create!(merge_hold: @hold, github_login: '@fluffy')
      assert_equal('fluffy', exemption.github_login)
    end
  end
end
