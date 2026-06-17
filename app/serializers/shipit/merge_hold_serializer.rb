# frozen_string_literal: true

module Shipit
  class MergeHoldSerializer < ActiveModel::Serializer
    has_one :author
    has_one :revoked_by
    has_one :stack

    attributes :id, :reason, :status, :starts_at, :ends_at, :activated_at,
               :deactivated_at, :revoked_at, :exempt_github_logins, :url, :created_at, :updated_at

    def url
      api_stack_merge_hold_url(object.stack, object)
    end

    def exempt_github_logins
      object.exempt_github_logins
    end
  end
end
