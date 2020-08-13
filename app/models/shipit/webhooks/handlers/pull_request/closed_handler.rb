# frozen_string_literal: true

module Shipit
  module Webhooks
    module Handlers
      module PullRequest
        class ClosedHandler < Shipit::Webhooks::Handlers::Handler
          params do
            requires :action
            requires :number
            requires :repository
            requires :sender
          end

          def process
            return unless respond_to_pull_request_closed?

            review_stack.archive!
          end

          private

          def repository
            @repository ||= Shipit::Repository.from_github_repo_name(params.repository["full_name"]) || Shipit::NullRepository.new
          end

          def review_stack
            @review_stack ||= Shipit::Webhooks::Handlers::PullRequest::ReviewStackAdapter.new(params, scope: repository.review_stacks)
          end

          def respond_to_pull_request_closed?
            params.action == "closed"
          end
        end
      end
    end
  end
end
