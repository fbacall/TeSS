module FieldLockEnforcement
  extend ActiveSupport::Concern

  included do
    before_filter :filter_locked_fields, only: :update,
                                         if: -> { current_user && current_user.has_role?(:scraper_user) }
  end

  def filter_locked_fields
    resource_type = controller_name.singularize
    resource = instance_variable_get("@#{resource_type}")

    params[resource_type].delete(:locked_fields)

    resource.locked_fields.each do |field|
      params[resource_type].delete(field)
    end
  end
end
