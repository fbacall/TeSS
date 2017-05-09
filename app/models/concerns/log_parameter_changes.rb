module LogParameterChanges
  extend ActiveSupport::Concern

  IGNORED_ATTRIBUTES = %w(id updated_at workflow_content last_scraped).freeze

  included do
    after_update :log_parameter_changes
  end

  class_methods do
    def is_foreign_key?(attr)
      return false unless attr.end_with?('_id')
      reflections.keys.include?(attr.chomp('_id'))
    end
  end

  def log_update_activity?
    (previous_changes.keys - IGNORED_ATTRIBUTES).any?
  end

  private

  def log_parameter_changes
    (changed - IGNORED_ATTRIBUTES).each do |changed_attribute|
      parameters = { attr: changed_attribute }
      if self.class.is_foreign_key?(changed_attribute)
        ob = self.send(changed_attribute.chomp('_id'))
        if ob
          parameters[:association_name] = ob.respond_to?(:title) ? ob.title : ob.name
        else
          parameters[:association_name] = nil
        end
      end
      parameters[:new_val] = self.send(changed_attribute)

      create_activity :update_parameter, parameters: parameters
    end
  end
end
