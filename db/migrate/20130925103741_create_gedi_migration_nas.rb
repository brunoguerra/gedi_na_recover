class CreateGediMigrationNas < ActiveRecord::Migration
  def change
    create_table :gedi_migration_nas do |t|
      t.string :number, :limit => 60
      t.date :emission
      t.infraction :references
      t.associated :integer
      t.notes :string, :limit => 120
      t.timestamps
    end

    add_index :gedi_migration_nas, :infraction_id
  end
end
