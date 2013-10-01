class GediMigrationViolatorAddress < ActiveRecord::Base
  belongs_to :violator
  attr_accessible :city, :desc, :district, :number, :state, :postal, :violator_id
  belongs_to :violator, :class_name => GediMigrationViolator
end
