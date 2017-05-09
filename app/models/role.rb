class Role < ActiveRecord::Base
  has_many :users

  # Look in config/data/roles.yml to find role definitions

  def self.fetch(name)
    role = find_by_name(name)
    if role
      role
    else
      create_roles
      find_by_name(name)
    end
  end

  # Use this with Role.create_roles on a new installation
  # to set the initial roles up if not using seeds.
  def self.create_roles
    roles = YAML.safe_load(File.read(File.join(Rails.root, 'config', 'data', 'roles.yml')))
    roles.each do |name, data|
      r = find_or_create_by(name: name)
      r.assign_attributes(data)
      r.save! if r.changed?
    end
  end
end
