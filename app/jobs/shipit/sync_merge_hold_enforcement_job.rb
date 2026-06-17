# frozen_string_literal: true

module Shipit
  class SyncMergeHoldEnforcementJob < BackgroundJob
    include BackgroundJob::Unique

    queue_as :default
    on_duplicate :drop

    def perform(repository)
      return unless repository

      MergeHoldEnforcer.sync!(repository)
    end
  end
end
