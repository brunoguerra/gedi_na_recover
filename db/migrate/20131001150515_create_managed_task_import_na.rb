class CreateManagedTaskImportNa < ActiveRecord::Migration
  def up
    Gedi::ManagedTask.create([
      {
        name: 'gedi_na_recover:recover',
        class_info: 'GediMigrationNA',
        task: 'gedi_na_recover:recover'
        interval: 1000*60*60*60
      },
    ])
  end

  def down
  end
end
