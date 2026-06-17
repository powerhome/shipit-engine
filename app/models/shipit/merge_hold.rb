# frozen_string_literal: true

module Shipit
  class MergeHold < Record
    belongs_to :stack
    belongs_to :author, class_name: 'User'
    belongs_to :revoked_by, class_name: 'User', optional: true

    has_many :exemptions, class_name: 'MergeHoldExemption', dependent: :destroy

    validates :reason, presence: true
    validate :starts_at_before_ends_at

    after_commit :emit_hooks
    after_commit :enforce_async

    scope :scheduled, -> { where(activated_at: nil, revoked_at: nil).where.not(starts_at: nil) }
    scope :active, -> { where.not(activated_at: nil).where(deactivated_at: nil, revoked_at: nil) }
    scope :historical, -> { where('deactivated_at IS NOT NULL OR revoked_at IS NOT NULL') }
    scope :ordered, -> { order(created_at: :desc) }

    def self.activate_due!(now: Time.current)
      where(activated_at: nil, revoked_at: nil)
        .where('starts_at IS NULL OR starts_at <= ?', now)
        .find_each(&:activate!)
    end

    def self.deactivate_expired!(now: Time.current)
      active
        .where.not(ends_at: nil)
        .where('ends_at <= ?', now)
        .find_each(&:deactivate!)
    end

    def active?
      activated_at.present? && deactivated_at.nil? && revoked_at.nil?
    end

    def scheduled?
      activated_at.nil? && revoked_at.nil? && starts_at.present? && starts_at > Time.current
    end

    def revoked?
      revoked_at.present?
    end

    def expired?
      deactivated_at.present? && revoked_at.nil?
    end

    def status
      return 'revoked' if revoked?
      return 'expired' if expired?
      return 'active' if active?
      return 'scheduled' if scheduled?

      'pending'
    end

    def activate!
      return false if revoked? || activated_at.present?

      update!(activated_at: Time.current)
    end

    def deactivate!
      return false unless active?

      update!(deactivated_at: Time.current)
    end

    def revoke!(user)
      return false if revoked? || expired?

      now = Time.current
      attrs = { revoked_at: now, revoked_by: user }
      attrs[:deactivated_at] = now if active?
      update!(attrs)
    end

    def exempt_github_logins
      exemptions.pluck(:github_login)
    end

    def exempt_github_logins=(logins)
      desired = Array(logins).flat_map { |l| l.to_s.split(/[\s,]+/) }.map(&:strip).reject(&:blank?).uniq
      exemptions.where.not(github_login: desired).destroy_all
      existing = exemptions.pluck(:github_login)
      (desired - existing).each do |login|
        exemptions.build(github_login: login)
      end
    end

    private

    def starts_at_before_ends_at
      return if starts_at.blank? || ends_at.blank?

      errors.add(:ends_at, 'must be after starts at') if ends_at <= starts_at
    end

    def emit_hooks
      Hook.emit(:merge_hold, stack, merge_hold: self, status: status)
    end

    def enforce_async
      SyncMergeHoldEnforcementJob.perform_later(stack.repository)
    end
  end
end
