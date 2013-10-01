class CreateGediMigrationViolators < ActiveRecord::Migration
  def change
    create_table :gedi_migration_violators do |t|
      t.string :name
      t.string :doc

      t.timestamps
    end
  end
end
