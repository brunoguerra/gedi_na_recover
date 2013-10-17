class CreateManagedTaskGediNaRecoverNpFileImporter < ActiveRecord::Migration
  def up
    Gedi::ManagedTask.create([
      {
        name: 'gedi_na_recover.detran.np_file_importer',
        class_info: 'NPFileImporter',
        task: 'gedi_na_recover:detran:np:importer',
        interval: 1000*60*60*60
      },
    ])
  end

  def down
  end
end
