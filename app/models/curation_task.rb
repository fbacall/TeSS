class CurationTask < ApplicationRecord
  belongs_to :resource, polymorphic: true
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :completed_by, class_name: 'User', optional: true

  PRIORITY = {
      low: -10,
      medium: 0,
      high: 10,
  }.freeze

  def self.open
    where(status: 'open')
  end

  def resolve
    update_attributes(completed_by: User.current_user, status: 'resolved')
  end
end
