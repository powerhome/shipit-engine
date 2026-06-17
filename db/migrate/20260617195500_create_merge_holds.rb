class CreateMergeHolds < ActiveRecord::Migration[7.1]
  def change
    create_table(:merge_holds) do |t|
      t.references(:stack, null: false, index: true)
      t.references(:author, null: true, index: true)
      t.references(:revoked_by, null: true, index: true)
      t.text(:reason, null: false)
      t.datetime(:starts_at, null: true)
      t.datetime(:ends_at, null: true)
      t.datetime(:activated_at, null: true)
      t.datetime(:deactivated_at, null: true)
      t.datetime(:revoked_at, null: true)
      t.timestamps
    end

    add_index(:merge_holds, %i[stack_id activated_at deactivated_at revoked_at], name: "index_merge_holds_on_stack_and_status")
  end
end
