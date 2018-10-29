class CreateCurationTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :curation_tasks do |t|
      t.string :key
      t.json :details
      t.references :resource, polymorphic: true, index: true
      t.string :status, default: 'open'
      t.references :assignee, foreign_key: { to_table: :users }, index: true
      t.references :completed_by, foreign_key: { to_table: :users }
      t.integer :priority, default: 0

      t.timestamps
    end
  end
end
