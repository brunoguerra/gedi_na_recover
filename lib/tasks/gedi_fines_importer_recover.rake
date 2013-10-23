require 'rails_config'
require "detran/ce/fines"
require 'gedi/detran/ce/implantacao_multas'
require 'fileutils'
#require 'ftools'
namespace :gedi_na_recover do
  namespace :detran do
    namespace :np do
      task export: :environment do
        load Rails.root.join('config/initializers/rails_config.rb')
        RailsConfig::Integration::Rails3.load!
        
        @exporter = Gedi::Analysis::PlateQuery::Exporter.new
        @exporter.path = Settings.plate_query.exporter.path
        result = @exporter.export!
        
        if result && @exporter.infractions_exported > 0
          @managed_task = Gedi::ManagedTask.where(name: 'detran.plate_query.export').first
          @execution = @managed_task.new_execution
          msg = "Placas exportadas com sucesso: %d" % @exporter.infractions_exported
          puts msg
          @execution.add_log(msg)
          @execution.success!
        else
          puts "Nenhuma placa para ser exportada. (%s)" % result.to_s 
        end
      end
      
      desc 'Import NP File (L)'
      task import: :environment do
        result = false
        
        load_config
        puts "Starting NP Importation base path on #{@path_base}"

        @managed_task = Gedi::ManagedTask.where(name: 'gedi_na_recover.detran.np_file_importer').first
        files = Dir["#{@path_base}/L*"]
        @execution = @managed_task.new_execution if (files.size>0)
        
        begin
          files.each do |query_file|
            puts "Importing #{query_file}"
            importer = Gedi::Detran::Ce::ImplantacaoMulta::Importer.new( query_file )
            @execution.start! unless @execution.started?
            import_result = importer.import!
            
            # move files
            move_files query_file, import_result

            if (importer.successful?)
              puts "Importado com sucess: #{query_file}"
              @execution.add_successful_file(query_file)
              result = result && true
            else
              puts "Falha ao importar: #{query_file}"
              @execution.add_unsuccessful_file(query_file)
              result = false
            end
          end

          puts "Total not founded: #{Gedi::Detran::Ce::ImplantacaoMulta::Importer.not_found} "

          Rake::Task["gedi_na_recover:utils:link:vehicles"].reenable
          Rake::Task["gedi_na_recover:utils:link:vehicles"].invoke
        rescue Exception => e
          result = false
          @execution.add_exception(e)
          puts e.message
          puts e.backtrace
        end
        
        unless @execution.nil?
          if result
            @execution.success!
          else
            @execution.fail!
          end
        end
        
      end
    end
  end
end

def load_config
  load Rails.root.join('config/initializers/rails_config.rb')
  RailsConfig::Integration::Rails3.load!

  @path_base = Settings.np.importer.paths.base + Settings.np.importer.paths.input
  @path_success = Settings.np.importer.paths.base + Settings.np.importer.paths.successful
  @path_errors = Settings.np.importer.paths.base + Settings.np.importer.paths.errors
end

def move_files query_file, import_result
  #execution logs
  @execution.add_file_logs(Dir.glob(File.dirname(query_file)+"/*.log"))

  dest_path =  import_result ? @path_success : @path_errors
  FileUtils.makedirs dest_path
  FileUtils.mv(query_file, dest_path)
  FileUtils.mv(Dir[File.dirname(query_file)+"/*.log"], dest_path)
end
