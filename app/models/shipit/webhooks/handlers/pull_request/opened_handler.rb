# frozen_string_literal: true

module Shipit
  module Webhooks
    module Handlers
      module PullRequest
        class OpenedHandler < Shipit::Webhooks::Handlers::Handler
          params do
            requires :action
            requires :number
            requires :pull_request
            requires :repository
            requires :sender
          end

          def process
            return unless respond_to_pull_request_opened?

            Shipit::Webhooks::Handlers::PullRequest::ReviewStackAdapter.new(params, scope: repository.review_stacks).find_or_create!
          end

          private

          def repository
            @repository ||= Shipit::Repository.from_github_repo_name(params.repository["full_name"]) || Shipit::NullRepository.new
          end

          def pull_request
            params.pull_request
          end

          def respond_to_pull_request_opened?
            params.action == "opened" &&
              provision?
          end

          def provision?
            repository.review_stacks_enabled &&
              repository.provisioning_behavior_allow_all? ||
              (repository.provisioning_behavior_allow_with_label? && pull_request_has_provisioning_label?) ||
              (repository.provisioning_behavior_prevent_with_label? && !pull_request_has_provisioning_label?)
          end

          def pull_request_has_provisioning_label?
            pull_request_label_names.include?(repository.provisioning_label_name)
          end

          def pull_request_label_names
            Array.new(pull_request["labels"]).map { |label| label["name"] }
          end
        end
      end
    end
  end
end
