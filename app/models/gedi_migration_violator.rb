class GediMigrationViolator < ActiveRecord::Base
  attr_accessible :doc, :name
  has_one :vehicle, :class_name => GediMigrationVehicle, :foreign_key => :violator_id
end
