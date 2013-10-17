class GediMigrationNA < ActiveRecord::Base
  attr_accessible :emission, :number, :infraction_id, :reference, :notes
  belongs_to :infraction, :class_name => GediMigrationInfraction

  belongs_to :associated_infraction, :foreign_key => :associated, class_name: Gedi::Infraction

  as_enum :accept, [:not_assigned, :accepted, :rejected], :column => "status_id"

  validates :number, :uniqueness => true, :presence => true

  attr_accessor :valid

  def invalid(msg)
    @runtime_valid = false
    self.update_attribute(:notes, msg)
  end

  def runtime_valid!
    @runtime_valid = true
  end

  def runtime_valid?
    @runtime_valid
  end

  def create_process
    Gedi::InfractionProcess.where(:infraction_id => self.associated).first ||
      Gedi::InfractionProcess.create(:infraction_id => self.associated, :number => self.number)
  end
end
