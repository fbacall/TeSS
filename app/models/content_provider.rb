class ContentProvider < ActiveRecord::Base
  include PublicActivity::Common
  include LogParameterChanges

  extend FriendlyId
  friendly_id :title, use: :slugged

  has_many :materials, dependent: :destroy
  has_many :events, dependent: :destroy

  belongs_to :user
  belongs_to :node

  delegate :name, to: :node, prefix: true, allow_nil: true

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :url, :image_url, squish: false

  validates :title, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, url: true

  clean_array_fields(:keywords)

  # The order of these determines which providers have precedence when scraping.
  # Low -> High
  PROVIDER_TYPE = %w(Portal Organisation Project).freeze
  has_image(placeholder: '/assets/placeholder-organization.png')

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :title
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      text :description
      string :keywords, multiple: true
      string :node, multiple: true do
        node.name unless node.blank?
      end
      text :node do
        node.name unless node.blank?
      end
      string :content_provider_type
      integer :count do
        if events.count > materials.count
          events.count
        else
          materials.count
        end
      end
    end
    # :nocov:
  end

  # TODO: Add validations for these:
  # title:text url:text image_url:text description:text

  def self.facet_fields
    %w(keywords node content_provider_type)
  end

  def node_name=(name)
    self.node = Node.find_by_name(name)
  end

  def precedence
    PROVIDER_TYPE.index(content_provider_type)
  end
end
