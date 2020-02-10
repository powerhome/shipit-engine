class AddUserLoginToPullRequestsTable < ActiveRecord::Migration[6.0]
  def change
    change_table(:pull_requests) do |t|
      t.column :user_login, :string, limit: 255, null: true
    end
  end

  def down
    change_table(:pull_requests) do |t|
      t.remove :user_login
    end
  end
end
