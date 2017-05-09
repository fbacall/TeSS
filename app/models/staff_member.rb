class StaffMember < ActiveRecord::Base
  TRAINING_COORDINATOR_ROLE = 'Training coordinator'.freeze

  belongs_to :node

  validates :name, presence: true

  scope :training_coordinators, -> { where(role: TRAINING_COORDINATOR_ROLE) }
  scope :other_roles, -> { where.not(role: TRAINING_COORDINATOR_ROLE) }

  has_image(placeholder: '/assets/placeholder-person.png')
end
