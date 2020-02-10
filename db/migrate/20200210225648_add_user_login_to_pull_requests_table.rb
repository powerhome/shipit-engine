class AddUserLoginToPullRequestsTable < ActiveRecord::Migration[6.0]
  def change
    change_table(:pull_requests) do |t|
      t.column :user_login, :string, null: true
      t.column :user_email, :string, null: true
      t.column :user_name, :string, null: true
    end
  end

  def down
    change_table(:pull_requests) do |t|
      t.remove :user_login
      t.remove :user_email
      t.remove :user_name
    end
  end
end
