class AddReviewRequestColumnToPullRequestsTable < ActiveRecord::Migration[6.0]
  def change
    change_table(:pull_requests) do |t|
      t.boolean :review_request, null: true, default: false
    end
  end
end
