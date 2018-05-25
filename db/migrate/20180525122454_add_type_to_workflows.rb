class AddTypeToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :type, :string
  end
end
