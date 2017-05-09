class ExternalResource < ActiveRecord::Base
  belongs_to :source, polymorphic: true

  validates :title, :url, presence: true
  validates :url, url: true

  BIOTOOLS_BASE = 'https://bio.tools'.freeze
  BIOSHARING_BASE = 'https://biosharing.org'.freeze

  def is_tool?
    url.starts_with?(BIOTOOLS_BASE)
  end

  def is_biosharing?
    url.starts_with?(BIOSHARING_BASE)
  end

  def is_generic_external_resource?
    !url.starts_with?(BIOSHARING_BASE, BIOTOOLS_BASE)
  end

  def api_url_of_tool
    return BIOTOOLS_BASE + '/api' + tool_id if is_tool?
    ''
  end

  private

  def tool_id
    return URI.split(url)[5] if is_tool?
    ''
  end

  def self.biotools_api_base_url
    BIOTOOLS_BASE + '/api'
  end
end
