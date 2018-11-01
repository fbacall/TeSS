module Curatable
  extend ActiveSupport::Concern

  included do
    has_many :curation_tasks, as: :resource, inverse_of: :resource
    attr_writer :related_curation_task
    after_create :notify_curators, if: :user_requires_approval?
    after_save :update_curation_task, if: :was_curated?
  end

  class_methods do
    def from_verified_users
      joins(user: :role).where.not(users: { role_id: [Role.rejected.id, Role.fetch('unverified_user').id] })
    end
  end

  def user_requires_approval?
    user && user.has_role?('unverified_user') && (user.created_resources - [self]).none?
  end

  def notify_curators
    CurationMailer.user_requires_approval(self.user).deliver_later
  end

  def update_curation_task
    @related_curation_task.resolve
  end

  def was_curated?
    (defined? @related_curation_task) && !!@related_curation_task
  end

  def handle_edit_suggestion_destroy
    curation_tasks.open.where(key: 'review_suggestions').each(&:resolve)
  end
end
