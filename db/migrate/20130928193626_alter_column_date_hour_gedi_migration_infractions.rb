class AlterColumnDateHourGediMigrationInfractions < ActiveRecord::Migration
  def up
    remove_column :gedi_migration_infractions, :date
    remove_column :gedi_migration_infractions, :hour
    add_column :gedi_migration_infractions, :date, :datetime
  end

  def down
  end
end
