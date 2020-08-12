# frozen_string_literal: true

module Shipit
  module Webhooks
    module Handlers
      module PullRequest
        class ReviewStackAdapter
          delegate :archived?, to: :stack

          def initialize(params, scope: Shipit::ReviewStack)
            @params = params
            @scope = scope
          end

          def stack
            @stack ||= scope.find_by(environment: environment)
          end

          def tracked?
            stack.present?
          end

          def find_or_create!
            stack || create!
          end

          def archive!(*args, &block)
            if stack.blank?
              Rails.logger.info "Archiving in response to PR #{action} event for #{repo_name} PR #{pr_number} but no Stack " \
                                "exists. Ignoring."
              return true
            end
            return if stack.archived?

            stack.deprovision
            stack.archive!(user, *args, &block)
          end

          def unarchive!(*args, &block)
            if stack.blank?
              Rails.logger.info "Unarchiving in response to PR #{action} event for #{repo_name} PR #{pr_number} but no Stack " \
                                "exists. Provisioning the stack instead."
              return create!
            end
            return unless stack.archived?

            stack.transaction do
              stack.unarchive!(*args, &block)
              Shipit::ReviewStackProvisioningQueue.add(stack)
            end
          end

          def user
            @user ||= Shipit::User.find_or_create_by_login!(params.sender["login"])
          end

          private

          attr_reader :params, :scope

          def action
            params.action
          end

          def repo_name
            params.repository["full_name"]
          end

          def pr_number
            params.number
          end

          def create!
            ensure_user_exists
            stack = scope.create(stack_attributes)
            Shipit::ReviewStackProvisioningQueue.add(stack)
            stack.save!
            Shipit::MergeRequest.assign_to_stack!(stack, pr_number)
            @stack = stack
          end

          def ensure_user_exists
            user
          end

          def stack_attributes
            {
              branch: params.pull_request["head"]["ref"],
              environment: environment,
              ignore_ci: false,
              continuous_deployment: false,
            }
          end

          def environment
            "pr#{params.number}"
          end
        end
      end
    end
  end
end