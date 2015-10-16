class PurgeFieldsFromMaterials < ActiveRecord::Migration
  def change
    remove_column :materials, :local_updated_date
    remove_column :materials, :internal_submitter_id
    remove_column :materials, :submitter_id
  end
end
