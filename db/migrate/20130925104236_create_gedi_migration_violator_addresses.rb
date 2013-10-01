class CreateGediMigrationViolatorAddresses < ActiveRecord::Migration
  def change
    create_table :gedi_migration_violator_addresses do |t|
      t.references :violator
      t.string :desc,         :limit => 200
      t.string :number,       :limit => 20
      t.string :district,     :limit => 160 
      t.string :city,         :limit => 80 
      t.string :state,        :limit => 10
      t.string :postal,       :limit => 20

      t.timestamps
    end
    add_index :gedi_migration_violator_addresses, :violator_id
  end
end
