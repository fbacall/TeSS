class User < ActiveRecord::Base
  include ActionView::Helpers::ApplicationHelper

  include PublicActivity::Common

  has_paper_trail

  acts_as_token_authenticatable
  include Gravtastic
  gravtastic secure: true, size: 250

  extend FriendlyId
  friendly_id :username, use: :slugged

  attr_accessor :login

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :username
      text :email
    end
    # :nocov:
  end

  has_one :profile, inverse_of: :user, dependent: :destroy
  has_many :materials
  has_many :packages, dependent: :destroy
  has_many :workflows, dependent: :destroy
  has_many :content_providers
  has_many :events
  has_many :nodes
  belongs_to :role

  before_create :set_registered_user_role, :set_default_profile
  before_create :skip_email_confirmation_for_non_production

  before_destroy :reassign_owner

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, authentication_keys: [:login]

  validates :username,
            presence: true,
            case_sensitive: false,
            uniqueness: true

  validates :email,
            presence: true,
            case_sensitive: false

  validates_format_of :email, with: Devise.email_regexp

  accepts_nested_attributes_for :profile

  attr_accessor :publicize_email

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }]).first
    else
      where(conditions.to_h).first
    end
  end

  def set_registered_user_role
    self.role ||= Role.fetch('registered_user')
  end

  def set_default_profile
    self.profile ||= Profile.new
    self.profile.email = (email || unconfirmed_email) if publicize_email.to_s == '1'
  end

  # Check if user has a particular role
  def has_role?(role)
    self.role && self.role.name == role.to_s
  end

  def is_admin?
    has_role?('admin')
  end

  # Check if user is owner of a resource
  def is_owner?(resource)
    return false if resource.nil?
    return false unless resource.respond_to?('user'.to_sym)
    if self == resource.user
      return true
    else
      return false
    end
  end

  def is_curator?
    has_role?('curator')
  end

  def skip_email_confirmation_for_non_production
    # In development and test environments, set the user as confirmed
    # after creation but before save
    # so no confirmation emails are sent
    skip_confirmation! unless Rails.env.production?
  end

  def self.get_default_user
    where(role_id: Role.fetch('default_user').id).first_or_create(username: 'default_user',
                                                                  email: TeSS::Config.contact_email,
                                                                  password: SecureRandom.base64)
  end

  def name
    n = username.to_s
    if self.profile && self.profile.firstname
      n += " (#{self.profile.firstname} #{self.profile.surname})"
    end
  end

  def self.current_user=(user)
    Thread.current[:current_user] = user
  end

  def self.current_user
    Thread.current[:current_user]
  end

  # Keeps adding numbers to the end of a given username until it is unique
  def self.unique_username(username)
    unique_username = username
    number = 0

    while User.where(username: unique_username).any?
      unique_username = "#{username}#{number += 1}"
    end

    unique_username
  end

  def self.from_omniauth(auth)
    # TODO: Decide what to do about users who have an account but authenticate later on via Elixir AAI.
    # TODO: The code below will update their account to note the Elixir auth. but leave their password intact;
    # TODO: is this what we should be doing?
    # user = User.where(:provider => auth.provider, :uid => auth.uid).first
    # `auth.info` fields: email, first_name, gender, image, last_name, name, nickname, phone, urls
    user = User.where(email: auth.info.email).first
    if user
      if user.provider.nil? && user.uid.nil?
        user.uid = auth.uid
        user.provider = auth.provider
        user.save
      end
    else
      # Generate a unique username. Usernames provided by AAI may already be in use.
      user = User.new(provider: auth.provider,
                      uid: auth.uid,
                      email: auth.info.email,
                      username: User.unique_username(auth.info.nickname || auth.info.openid || 'user'),
                      password: Devise.friendly_token[0, 20],
                      profile_attributes: { firstname: auth.info.first_name,
                                            surname: auth.info.last_name })
      user.skip_confirmation!
    end

    user
  end

  private

  def reassign_owner
    # Material.where(:user => self).each do |material|
    #   material.update_attribute(:user, get_default_user)
    # end
    # Event.where(:user => self).each do |event|
    #   event.update_attribute(:user_id, get_default_user.id)
    # end
    # ContentProvider.where(:user => self).each do |content_provider|
    #   content_provider.update_attribute(:user_id, get_default_user.id)
    # end
    # Node.where(:user => self).each do |node|
    #   node.update_attribute(:user_id, get_default_user.id)
    # end
    default_user = User.get_default_user
    materials.each { |x| x.update_attribute(:user, default_user) } if materials.any?
    events.each { |x| x.update_attribute(:user, default_user) } if events.any?
    content_providers.each { |x| x.update_attribute(:user, default_user) } if content_providers.any?
    nodes.each { |x| x.update_attribute(:user, default_user) } if nodes.any?
  end
end
