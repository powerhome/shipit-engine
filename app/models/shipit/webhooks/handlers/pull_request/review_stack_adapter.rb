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

          def find_or_create!
            stack || create!
          end

          def archive!(*args, &block)
            if stack.blank?
              Rails.logger.info(
                "Processing #{action} event for #{repo_name} PR #{pr_number} but no Stack exists. Ignoring."
              )
              return true
            end
            return if stack.archived?

            stack.deprovision
            stack.archive!(user, *args, &block)
          end

          def unarchive!(*args, &block)
            if stack.blank?
              Rails.logger.info(
                "Processing #{action} event for #{repo_name} PR #{pr_number} but no ReviewStack exists. Creating."
              )
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
            stack = scope.build(stack_attributes)
            stack.pull_request = Shipit::PullRequest.from_github(params.pull_request)
            stack.save!
            Shipit::ReviewStackProvisioningQueue.add(stack)

            @stack = stack
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
