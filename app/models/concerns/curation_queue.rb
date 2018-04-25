module CurationQueue
  extend ActiveSupport::Concern

  included do
    after_create :notify_curators, if: :user_requires_approval?
  end

  def user_requires_approval?
    user && user.has_role?('unverified_user') && (user.created_resources - [self]).none?
  end

  def notify_curators
    CurationMailer.user_requires_approval(self.user).deliver_later
  end
end