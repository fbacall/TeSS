class PackageMaterial < ActiveRecord::Base
  belongs_to :material
  belongs_to :package

  include PublicActivity::Common

  self.primary_key = 'id'

  after_save :log_activity

  def log_activity
    package.create_activity(:add_material, owner: User.current_user,
                                           parameters: { material_id: material_id, material_title: material.title })
    material.create_activity(:add_to_package, owner: User.current_user,
                                              parameters: { package_id: package_id, package_title: package.title })
  end
end
