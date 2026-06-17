class CreateMergeHoldExemptions < ActiveRecord::Migration[7.1]
  def change
    create_table(:merge_hold_exemptions) do |t|
      t.references(:merge_hold, null: false, index: true)
      t.string(:github_login, null: false)
      t.timestamps
    end

    add_index(:merge_hold_exemptions, %i[merge_hold_id github_login], unique: true, name: "index_merge_hold_exemptions_on_hold_and_login")
  end
end
