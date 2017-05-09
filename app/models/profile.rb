class Profile < ActiveRecord::Base
  belongs_to :user, inverse_of: :profile

  #   extend FriendlyId
  #   friendly_id [:firstname, :surname], use: :slugged

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :firstname
      text :surname
      text :website
      text :email
      text :image_url
      time :updated_at
    end
    # :nocov:
  end

  # validates :email, presence: true
end
