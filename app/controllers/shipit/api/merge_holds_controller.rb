# frozen_string_literal: true

module Shipit
  module Api
    class MergeHoldsController < BaseController
      require_permission :read, :stack, only: %i[index show global_index]
      require_permission :lock, :stack, only: %i[create revoke]

      def index
        scope = stack.merge_holds.ordered
        render_resources(scope)
      end

      def global_index
        scope = MergeHold.active.includes(:stack, :author).ordered
        render_resources(scope)
      end

      def show
        merge_hold = stack.merge_holds.find(params[:id])
        render_resource(merge_hold)
      end

      params do
        requires :reason, String, presence: true
        accepts :starts_at, Time
        accepts :ends_at, Time
        accepts :exempt_github_logins, Array
      end
      def create
        merge_hold = stack.merge_holds.build(
          reason: params.reason,
          starts_at: params.starts_at,
          ends_at: params.ends_at,
          author: current_user
        )
        merge_hold.exempt_github_logins = params.exempt_github_logins if params.exempt_github_logins
        if merge_hold.save
          render_resource(merge_hold, status: :created)
        else
          render(status: :unprocessable_entity, json: { message: merge_hold.errors.full_messages.to_sentence })
        end
      end

      def revoke
        merge_hold = stack.merge_holds.find(params[:id])
        if merge_hold.revoke!(current_user)
          render_resource(merge_hold)
        else
          render(status: :conflict, json: { message: 'Merge hold cannot be revoked' })
        end
      end
    end
  end
end
