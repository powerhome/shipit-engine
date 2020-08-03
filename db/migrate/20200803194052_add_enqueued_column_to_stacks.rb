class AddEnqueuedColumnToStacks < ActiveRecord::Migration[6.0]
  def up
    add_column :stacks, :enqueued, :boolean, null: false, default: false
    add_index :stacks, :enqueued
  end

  def down
    remove_index :stacks, :enqueued
    remove_column :stacks, :enqueued
  end
end
