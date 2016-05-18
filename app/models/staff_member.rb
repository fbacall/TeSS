class StaffMember < ActiveRecord::Base
  TRAINING_COORDINATOR_ROLE = 'Training coordinator'

  belongs_to :node

  validates :name, presence: true

  scope :training_coordinators, -> { where(role: TRAINING_COORDINATOR_ROLE) }
end