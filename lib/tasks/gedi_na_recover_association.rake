
namespace :gedi_na_recover do
  namespace :utils do
    desc 'linkage with pre-data NAs'
    task :link => :environment do
      Time.zone = -3
      NARecover::Linkage.run
    end

    namespace :link do
      task :vehicles => :environment do
        GediMigrationNA.joins(
          {:associated_infraction => {:violator => :violator}}
        ).where(
          'gedi_infraction_violators.vehicle_id is null'
        ).each do |na|
          gedi_violator = na.associated_infraction.violator
          plate = na.infraction.violator.vehicle.plate.gsub /\-/, ''
          puts "Placa: #{plate}"
          puts "Violator: #{gedi_violator.id}"
          gedi_violator.vehicle = Gedi::Vehicle.where(%{plate ILIKE '#{plate}'}).first
          gedi_violator.save
        end
      end
    end
  end
end

###############################################################

module NARecover
  class Linkage

    def self.run
      Linkage.new().run
    end

    def run
      GediMigrationNA.where('associated is null').each do |na|
        @na = na
        setup
        next unless @na.runtime_valid?
        match = Gedi::Infraction.joins(:event, :infraction_type).where(
          datetime_start: @na.infraction.date, 
          equipment_id: @equipment.id,
          Gedi::Event.table_name => {
            speed: @na.infraction.speed_computed
          },
          Gedi::InfractionType.table_name => {
            code: (@na.infraction.code.to_s + @na.infraction.variant.to_s)
          }
        ).first

        if match
          @na.update_attribute(:associated, match.id)
          @na.create_process
        end
      end
    end

    def setup
      @na.runtime_valid! #yet

      @equipment = Gedi::Equipment.find_by_code @na.infraction.equipment.code
      @na.invalid('Equipment not found') if @equipment.nil?
    end
  end
end