class Package < ActiveRecord::Base
  include PublicActivity::Model
  include LogParameterChanges

  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  has_many :package_materials
  has_many :package_events
  has_many :materials, through: :package_materials
  has_many :events, through: :package_events

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :image_url, squish: false

  validates :title, presence: true

  clean_array_fields(:keywords)
  update_suggestions(:keywords)

  has_image(placeholder: '/assets/placeholder-package.png')

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :title
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      text :description
      string :user do
        user.username.to_s unless user.blank?
      end
      string :keywords, multiple: true

      string :user, multiple: true do
        if user
          if user.profile && (user.profile.firstname || user.profile.surname)
            "#{user.profile.firstname} #{user.profile.surname}"
          else
            user.username
          end
        end
      end

      integer :user_id
      boolean :public
    end
    # :nocov:
  end

  # Overwrites a packages materials and events.
  # [] or nil will delete
  def update_resources_by_id(materials = [], events = [])
    update_attribute('materials', materials.uniq.collect { |materials| Material.find_by_id(materials) }.compact) if materials
    update_attribute('events', events.uniq.collect { |events| Event.find_by_id(events) }.compact) if events
  end

  def self.facet_fields
    %w(user keywords)
  end

  def self.visible_by(user)
    if user && user.is_admin?
      all
    elsif user
      where("#{table_name}.public = ? OR #{table_name}.user_id = ?", true, user)
    else
      where(public: true)
    end
  end
end
