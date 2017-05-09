require 'rails/html/sanitizer'

class Material < ActiveRecord::Base
  include PublicActivity::Common
  include HasScientificTopics
  include LogParameterChanges
  include HasAssociatedNodes
  include HasExternalResources
  include HasContentProvider
  include HasLicence
  include LockableFields

  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :title
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      text :long_description
      text :short_description
      text :doi
      string :authors, multiple: true
      text :authors
      string :scientific_topics, multiple: true do
        scientific_topic_names
      end
      string :target_audience, multiple: true
      text :target_audience
      string :keywords, multiple: true
      text :keywords
      string :difficulty_level do
        Tess::DifficultyDictionary.instance.lookup_value(difficulty_level, 'title')
      end
      text :difficulty_level
      string :contributors, multiple: true
      text :contributors
      string :content_provider do
        content_provider.title unless content_provider.nil?
      end
      text :content_provider do
        content_provider.title unless content_provider.nil?
      end
      string :node, multiple: true do
        associated_nodes.map(&:name)
      end
      string :submitter, multiple: true do
        submitter_index
      end
      text :submitter do
        submitter_index
      end
      time :updated_at
      time :created_at
      time :last_scraped
      string :user do
        user.username if user
      end
    end
    # :nocov:
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user
  has_one :edit_suggestion, as: :suggestible, dependent: :destroy
  has_many :package_materials
  has_many :packages, through: :package_materials
  has_many :event_materials
  has_many :events, through: :event_materials

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :short_description, :long_description, :url, squish: false

  validates :title, :short_description, :url, presence: true

  validates :url, url: true

  validates :difficulty_level, controlled_vocabulary: { dictionary: Tess::DifficultyDictionary.instance }

  clean_array_fields(:keywords, :contributors, :authors, :target_audience)

  update_suggestions(:keywords, :contributors, :authors, :target_audience)

  def short_description=(desc)
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def long_description=(desc)
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def self.facet_fields
    %w( scientific_topics tools standard_database_or_policy target_audience keywords difficulty_level
        authors related_resources contributors licence node content_provider user )
  end

  private

  def submitter_index
    if user = User.find_by_id(user_id)
      if user.profile.firstname || user.profile.surname
        "#{user.profile.firstname} #{user.profile.surname}"
      else
        user.username
      end
    end
  end
end
