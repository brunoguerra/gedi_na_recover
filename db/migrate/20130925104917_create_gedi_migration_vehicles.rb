class CreateGediMigrationVehicles < ActiveRecord::Migration
  def change
    create_table :gedi_migration_vehicles do |t|
      t.string :plate
      t.string :mark_model
      t.references :violator

      t.timestamps
    end
    add_index :gedi_migration_vehicles, :violator_id
  end
end
