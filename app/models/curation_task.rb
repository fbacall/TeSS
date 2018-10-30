class CurationTask < ApplicationRecord
  belongs_to :resource, polymorphic: true
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :completed_by, class_name: 'User', optional: true

  validates :status, inclusion: ['open', 'resolved']
  validates :key, inclusion: ['update', 'locate'] # TODO: Come up with some more tasks

  PRIORITY = {
      low: -10,
      medium: 0,
      high: 10,
  }.freeze

  def self.open
    where(status: 'open')
  end

  def self.unassigned
    where(assignee_id: nil)
  end

  # All curation tasks assigned to the user, ordered by priority, then any unassigned tasks (also by priority)
  def self.queue_for_user(user)
    open.where(assignee_id: [user, nil]).order('assignee_id ASC, priority DESC')
  end

  def title
    "Task: #{key.titleize} #{resource_type}"
  end

  def resolve
    update_attributes(completed_by: User.current_user, status: 'resolved')
  end

  def open?
    status == 'open'
  end
end
