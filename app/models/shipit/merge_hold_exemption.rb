# frozen_string_literal: true

module Shipit
  class MergeHoldExemption < Record
    belongs_to :merge_hold

    validates :github_login, presence: true, uniqueness: { scope: :merge_hold_id }

    before_validation :normalize_login

    private

    def normalize_login
      self.github_login = github_login.to_s.strip.sub(/\A@/, '')
    end
  end
end
