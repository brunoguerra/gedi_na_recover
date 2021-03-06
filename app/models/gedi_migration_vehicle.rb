class GediMigrationVehicle < ActiveRecord::Base
  belongs_to :violator
  attr_accessible :mark_model, :plate, :violator_id, :specie
  belongs_to :violator, :class_name => GediMigrationViolator
end
