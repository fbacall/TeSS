class AddDefaultValueToCurationTasksKey < ActiveRecord::Migration[5.2]
  def change
    change_column_default :curation_tasks, :key, 'update'
    CurationTask.find_each do |ct|
      if ct.key.blank?
        ct.update_column(:key, 'update')
      end
    end
  end
end
