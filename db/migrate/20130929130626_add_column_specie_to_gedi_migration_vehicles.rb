class AddColumnSpecieToGediMigrationVehicles < ActiveRecord::Migration
  def change
    add_column :gedi_migration_vehicles, :specie, :string
  end
end
