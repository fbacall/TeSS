class AddTypeToWorkflows < ActiveRecord::Migration[4.2]
  def change
    add_column :workflows, :type, :string
  end
end
