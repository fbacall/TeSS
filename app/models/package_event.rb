class PackageEvent < ActiveRecord::Base
  belongs_to :event
  belongs_to :package

  include PublicActivity::Common

  self.primary_key = 'id'

  after_save :log_activity

  def log_activity
    package.create_activity(:add_event, owner: User.current_user,
                                        parameters: { event_id: event_id, event_title: event.title })
    event.create_activity(:add_to_package, owner: User.current_user,
                                           parameters: { package_id: package_id, package_title: package.title })
  end
end
