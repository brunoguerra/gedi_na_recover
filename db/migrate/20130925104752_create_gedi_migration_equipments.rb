class CreateGediMigrationEquipments < ActiveRecord::Migration
  def change
    create_table :gedi_migration_equipments do |t|
      t.string :code
      t.string :local

      t.timestamps
    end
  end
end
