class GediMigrationInfraction < ActiveRecord::Base
  belongs_to :equipment, :class_name => GediMigrationEquipment
  attr_accessible :code, :date, :hour, :lane, :speed_computed, :speed_legal, :variant, :equipment_id, :violator_id
  belongs_to :violator, :class_name => GediMigrationViolator
end
