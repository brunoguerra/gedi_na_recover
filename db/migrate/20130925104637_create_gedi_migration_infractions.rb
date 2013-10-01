class CreateGediMigrationInfractions < ActiveRecord::Migration
  def change
    create_table :gedi_migration_infractions do |t|
      t.date :date
      t.time :hour
      t.references :violator
      t.string :code
      t.string :variant
      t.float :speed_legal
      t.float :speed_computed
      t.references :equipment
      t.integer :lane

      t.timestamps
    end
    add_index :gedi_migration_infractions, :violator_id
    add_index :gedi_migration_infractions, :equipment_id
  end
end
