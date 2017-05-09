require 'icalendar'
require 'rails/html/sanitizer'

class Event < ActiveRecord::Base
  include PublicActivity::Common
  include LogParameterChanges
  include HasAssociatedNodes
  include HasScientificTopics
  include HasExternalResources
  include HasContentProvider
  include LockableFields

  has_paper_trail
  before_save :set_default_times, :check_country_name

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
      text :url
      string :organizer
      text :organizer
      string :sponsor
      text :sponsor
      string :venue
      text :venue
      string :city
      text :city
      string :country
      text :country
      string :event_types, multiple: true do
        Tess::EventTypeDictionary.instance.values_for_search(event_types)
      end
      string :keywords, multiple: true
      time :start
      time :end
      time :updated_at
      string :content_provider do
        content_provider.title unless content_provider.nil?
      end
      text :content_provider do
        content_provider.title unless content_provider.nil?
      end
      string :node, multiple: true do
        associated_nodes.map(&:name)
      end
      string :scientific_topics, multiple: true do
        scientific_topic_names
      end
      string :target_audience, multiple: true
      boolean :online
      text :host_institutions
      time :last_scraped
      text :timezone
      string :user do
        user.username if user
      end
      # TODO: SOLR has a LatLonType to do geospatial searching. Have a look at that
      #       location :latitutde
      #       location :longitude
    end
    # :nocov:
  end

  belongs_to :user
  has_one :edit_suggestion, as: :suggestible, dependent: :destroy
  has_many :package_events
  has_many :packages, through: :package_events
  has_many :event_materials
  has_many :materials, through: :event_materials

  validates :title, :url, presence: true
  validates :capacity, numericality: true, allow_blank: true
  validates :event_types, controlled_vocabulary: { dictionary: Tess::EventTypeDictionary.instance }
  validates :eligibility, controlled_vocabulary: { dictionary: Tess::EligibilityDictionary.instance }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true }

  clean_array_fields(:keywords, :event_types, :target_audience, :eligibility, :host_institutions)
  update_suggestions(:keywords, :target_audience, :host_institutions)

  COUNTRY_SYNONYMS = JSON.parse(File.read(File.join(Rails.root, 'config', 'data', 'country_synonyms.json')))

  # Generated Event:
  # external_id:string
  # title:string
  # subtitle:string
  # url:string
  # organizer:string
  # description:text
  # event_types:text
  # start:datetime
  # end:datetime
  # sponsor:string
  # venue:text
  # city:string
  # county:string
  # country:string
  # postcode:string
  # latitude:double
  # longitude:double

  def description=(desc)
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def upcoming?
    # Handle nil for start date
    if start.blank?
      true
    else
      (Time.now < start)
    end
  end

  def started?
    if start && self.end
      (Time.now > start && Time.now < self.end)
    else
      false
    end
  end

  def expired?
    if self.end
      Time.now > self.end
    else
      false
    end
  end

  def self.facet_fields
    %w( scientific_topics event_types online country tools organizer city sponsor target_audience keywords
        venue node content_provider user )
  end

  def to_csv_event
    organizer = if organizer.class == String
                  self.organizer.tr(',', ' ')
                elsif self.organizer.class == Array
                  self.organizer.join(' | ').gsub(',', ' and ')
                end
    cp = content_provider.title unless content_provider.nil?

    [title.tr(',', ' '),
     organizer,
     start.strftime('%d %b %Y'),
     self.end.strftime('%d %b %Y'),
     cp]
  end

  def to_ical
    cal = Icalendar::Calendar.new
    cal.add_event(to_ical_event)
    cal.to_ical
  end

  def to_ical_event
    Icalendar::Event.new.tap do |ical_event|
      ical_event.dtstart     = Icalendar::Values::Date.new(start) unless start.blank?
      ical_event.dtend       = Icalendar::Values::Date.new(self.end) unless self.end.blank?
      ical_event.summary     = title
      ical_event.description = description
      ical_event.location    = venue unless venue.blank?
    end
  end

  def show_map?
    !(online? || latitude.blank? || longitude.blank?)
  end

  def all_day?
    start && self.end && (start == start.midnight) || (self.end == self.end.midnight)
  end

  # Ticket #375.
  # Default end at start +1 hour for online events.
  # Default end at 17:00 same day otherwise.
  # Default start time 9am.
  def set_default_times
    return unless start

    self.start = start + 9.hours if start.hour == 0 # hour set to 0 if not otherwise defined...

    unless self.end
      if online?
        self.end = start + 1.hour
      else
        diff = 17 - start.hour
        self.end = start + diff.hours
      end
    end
    # TODO: Set timezone for online events. Where to get it from, though?
    # TODO: Check events form to add timezone autocomplete.
    # Get timezones from: https://timezonedb.com/download
  end

  def self.not_finished
    where('events.end > ?', Time.now).where.not(end: nil)
  end

  def self.finished
    where('events.end < ?', Time.now).where.not(end: nil)
  end

  # Ticket #423
  def check_country_name
    return unless country
    if country.respond_to?(:parameterize)
      text = country.parameterize.underscore.humanize.downcase
      self.country = COUNTRY_SYNONYMS[text] if COUNTRY_SYNONYMS[text]
    end
  end
end
