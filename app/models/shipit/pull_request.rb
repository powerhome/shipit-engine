# frozen_string_literal: true

module Shipit
  class PullRequest < Record
    include DeferredTouch

    belongs_to :stack
    belongs_to :user
    belongs_to :head, class_name: 'Shipit::Commit', optional: true

    has_many :pull_request_assignments
    has_many :assignees, class_name: :User, through: :pull_request_assignments, source: :user

    has_many :pull_request_labels
    has_many :labels, through: :pull_request_labels

    def github_pull_request=(github_pull_request)
      self.github_id = github_pull_request.id
      self.number = github_pull_request.number
      self.api_url = github_pull_request.url
      self.title = github_pull_request.title
      self.state = github_pull_request.state
      self.additions = github_pull_request.additions
      self.deletions = github_pull_request.deletions
      self.user = User.find_or_create_by_login!(github_pull_request.user.login)
      self.assignees = github_pull_request.assignees.map do |github_user|
        User.find_or_create_by_login!(github_user.login)
      end
      self.labels = github_pull_request.labels.map do |github_label|
        Label.find_or_create_from_github!(github_label)
      end
      self.head = find_or_create_commit_from_github_by_sha!(github_pull_request.head.sha)
    end

    def find_or_create_commit_from_github_by_sha!(sha)
      if commit = stack.commits.by_sha(sha)
        commit
      else
        github_commit = Shipit.github.api.commit(stack.github_repo_name, sha)
        stack.commits.create_from_github!(github_commit)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
