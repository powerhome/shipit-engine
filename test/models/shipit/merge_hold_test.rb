# frozen_string_literal: true

require 'test_helper'

module Shipit
  class MergeHoldTest < ActiveSupport::TestCase
    setup do
      @stack = shipit_stacks(:shipit)
      @user = shipit_users(:walrus)
    end

    test "valid hold can be created" do
      hold = @stack.merge_holds.build(reason: 'Investigating', author: @user)
      assert_predicate(hold, :valid?)
    end

    test "requires a reason" do
      hold = @stack.merge_holds.build(author: @user)
      refute_predicate(hold, :valid?)
      assert_includes(hold.errors[:reason], "can't be blank")
    end

    test "ends_at must be after starts_at" do
      hold = @stack.merge_holds.build(
        reason: 'X',
        author: @user,
        starts_at: 1.day.from_now,
        ends_at: 1.hour.from_now
      )
      refute_predicate(hold, :valid?)
      assert_includes(hold.errors[:ends_at], 'must be after starts at')
    end

    test "#active? is true when activated and not deactivated or revoked" do
      hold = shipit_merge_holds(:shipit_active)
      assert_predicate(hold, :active?)
      assert_equal('active', hold.status)
    end

    test "#scheduled? is true when starts_at is in the future and not yet activated" do
      hold = shipit_merge_holds(:shipit_scheduled)
      assert_predicate(hold, :scheduled?)
      assert_equal('scheduled', hold.status)
    end

    test "#revoked? is true when revoked_at is set" do
      hold = shipit_merge_holds(:shipit_revoked)
      assert_predicate(hold, :revoked?)
      assert_equal('revoked', hold.status)
    end

    test "#expired? is true when deactivated_at set without revoke" do
      hold = @stack.merge_holds.create!(
        reason: 'X',
        author: @user,
        activated_at: 1.day.ago,
        deactivated_at: 1.hour.ago
      )
      assert_predicate(hold, :expired?)
      assert_equal('expired', hold.status)
    end

    test "scope :active returns only active holds" do
      active = MergeHold.active.to_a
      assert_includes(active, shipit_merge_holds(:shipit_active))
      refute_includes(active, shipit_merge_holds(:shipit_revoked))
      refute_includes(active, shipit_merge_holds(:shipit_scheduled))
    end

    test "scope :scheduled returns only future scheduled holds" do
      scheduled = MergeHold.scheduled.to_a
      assert_includes(scheduled, shipit_merge_holds(:shipit_scheduled))
      refute_includes(scheduled, shipit_merge_holds(:shipit_active))
    end

    test "scope :historical returns deactivated or revoked holds" do
      historical = MergeHold.historical.to_a
      assert_includes(historical, shipit_merge_holds(:shipit_revoked))
      refute_includes(historical, shipit_merge_holds(:shipit_active))
    end

    test ".activate_due! activates holds whose starts_at has passed" do
      hold = @stack.merge_holds.create!(
        reason: 'soon',
        author: @user,
        starts_at: 1.hour.ago
      )
      assert_nil(hold.activated_at)

      MergeHold.activate_due!

      assert_not_nil(hold.reload.activated_at)
    end

    test ".activate_due! does not activate revoked holds" do
      hold = @stack.merge_holds.create!(
        reason: 'soon',
        author: @user,
        starts_at: 1.hour.ago,
        revoked_at: 30.minutes.ago,
        revoked_by: @user
      )

      MergeHold.activate_due!

      assert_nil(hold.reload.activated_at)
    end

    test ".activate_due! does not activate future-scheduled holds" do
      hold = shipit_merge_holds(:shipit_scheduled)

      MergeHold.activate_due!

      assert_nil(hold.reload.activated_at)
    end

    test ".deactivate_expired! deactivates active holds whose ends_at has passed" do
      hold = @stack.merge_holds.create!(
        reason: 'expiring',
        author: @user,
        activated_at: 2.hours.ago,
        ends_at: 1.hour.ago
      )

      MergeHold.deactivate_expired!

      assert_not_nil(hold.reload.deactivated_at)
    end

    test ".deactivate_expired! does not deactivate active holds without ends_at" do
      hold = shipit_merge_holds(:shipit_active)

      MergeHold.deactivate_expired!

      assert_nil(hold.reload.deactivated_at)
    end

    test "#activate! sets activated_at" do
      hold = @stack.merge_holds.create!(reason: 'r', author: @user, starts_at: 1.day.from_now)
      assert_nil(hold.activated_at)
      assert(hold.activate!)
      assert_not_nil(hold.reload.activated_at)
    end

    test "#activate! returns false when already activated" do
      hold = shipit_merge_holds(:shipit_active)
      refute(hold.activate!)
    end

    test "#deactivate! sets deactivated_at" do
      hold = shipit_merge_holds(:shipit_active)
      assert(hold.deactivate!)
      assert_not_nil(hold.reload.deactivated_at)
    end

    test "#deactivate! returns false when not active" do
      hold = shipit_merge_holds(:shipit_revoked)
      refute(hold.deactivate!)
    end

    test "#revoke! marks the hold as revoked and deactivates if active" do
      hold = shipit_merge_holds(:shipit_active)
      assert(hold.revoke!(@user))
      hold.reload
      assert_not_nil(hold.revoked_at)
      assert_not_nil(hold.deactivated_at)
      assert_equal(@user, hold.revoked_by)
    end

    test "#revoke! returns false if already revoked" do
      hold = shipit_merge_holds(:shipit_revoked)
      refute(hold.revoke!(@user))
    end

    test "#exempt_github_logins= splits strings and dedupes" do
      hold = @stack.merge_holds.create!(reason: 'r', author: @user)
      hold.exempt_github_logins = 'walrus, dependabot walrus'
      hold.save!
      assert_equal(%w[walrus dependabot].sort, hold.exempt_github_logins.sort)
    end

    test "#exempt_github_logins= removes logins not in new set" do
      hold = shipit_merge_holds(:shipit_active)
      assert_includes(hold.exempt_github_logins, 'walrus')
      hold.exempt_github_logins = ['dependabot']
      hold.save!
      assert_equal(['dependabot'], hold.reload.exempt_github_logins)
    end

    test "creating a hold enqueues a SyncMergeHoldEnforcementJob" do
      assert_enqueued_with(job: SyncMergeHoldEnforcementJob) do
        @stack.merge_holds.create!(reason: 'r', author: @user, activated_at: Time.current)
      end
    end

    test "creating a hold emits the merge_hold hook" do
      expect_hook(:merge_hold, @stack) do
        @stack.merge_holds.create!(reason: 'r', author: @user, activated_at: Time.current)
      end
    end
  end
end
