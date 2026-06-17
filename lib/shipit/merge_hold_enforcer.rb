# frozen_string_literal: true

module Shipit
  class MergeHoldEnforcer
    DEFAULT_RULESET_NAME = 'Shipit Merge Hold'

    class GitHubError < StandardError; end

    class << self
      def sync!(repository)
        new(repository).sync!
      end
    end

    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end

    def sync!
      active_holds = MergeHold.active.where(stack_id: repository.stacks.select(:id)).to_a
      desired = build_desired_state(active_holds)
      existing = fetch_ruleset

      if desired.nil?
        delete_ruleset(existing) if existing
        return
      end

      if existing
        update_ruleset(existing, desired)
      else
        create_ruleset(desired)
      end
    end

    private

    def ruleset_name
      Shipit.merge_hold_ruleset_name
    end

    def build_desired_state(active_holds)
      return nil if active_holds.empty?

      branches = active_holds.map { |hold| hold.stack.branch }.compact.uniq.sort
      return nil if branches.empty?

      exempt_logins = active_holds.flat_map(&:exempt_github_logins).uniq.sort
      {
        name: ruleset_name,
        target: 'branch',
        enforcement: 'active',
        bypass_actors: bypass_actors_for(exempt_logins),
        conditions: {
          ref_name: {
            include: branches.map { |b| "refs/heads/#{b}" },
            exclude: []
          }
        },
        rules: [
          { type: 'non_fast_forward' },
          { type: 'update' }
        ]
      }
    end

    def bypass_actors_for(logins)
      logins.filter_map do |login|
        actor_id = lookup_user_id(login)
        next if actor_id.nil?

        {
          actor_id:,
          actor_type: 'Integration',
          bypass_mode: 'always'
        }
      end
    end

    def lookup_user_id(login)
      user = github_client.user(login)
      user&.id
    rescue Octokit::NotFound
      nil
    end

    def fetch_ruleset
      rulesets = github_client.get("/repos/#{repository.full_name}/rulesets")
      ruleset = rulesets.find { |r| r.name == ruleset_name }
      return nil unless ruleset

      github_client.get("/repos/#{repository.full_name}/rulesets/#{ruleset.id}")
    rescue Octokit::NotFound, Octokit::Forbidden
      nil
    end

    def create_ruleset(desired)
      github_client.post("/repos/#{repository.full_name}/rulesets", desired)
    rescue Octokit::Error => e
      raise GitHubError, "Failed to create ruleset: #{e.message}"
    end

    def update_ruleset(existing, desired)
      github_client.put("/repos/#{repository.full_name}/rulesets/#{existing.id}", desired)
    rescue Octokit::Error => e
      raise GitHubError, "Failed to update ruleset: #{e.message}"
    end

    def delete_ruleset(existing)
      github_client.delete("/repos/#{repository.full_name}/rulesets/#{existing.id}")
    rescue Octokit::Error => e
      raise GitHubError, "Failed to delete ruleset: #{e.message}"
    end

    def github_client
      Shipit.github(organization: repository.owner).api
    end
  end
end
