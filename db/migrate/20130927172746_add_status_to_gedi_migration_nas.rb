class AddStatusToGediMigrationNas < ActiveRecord::Migration
  def change
    add_column :gedi_migration_nas, :status_id, :integer, :default => 0
    add_column :gedi_migration_nas, :reference, :string, :limit => 120
    add_index :gedi_migration_nas, :status_id
  end
end
