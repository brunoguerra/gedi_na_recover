# encoding: UTF-8
require "gedi/analysis/plate_query"
module Gedi
  class NasController < Gedi::BaseController
    load_and_authorize_resource :class => "GediMigrationNA", :except => [:list, :generate, :accept]

    def index
    end
    
    def list
      status = params[:status] || 0
      search status
      @nas = paginate @search, nil, 5
      render :layout => false
      authorize! :read, GediMigrationNA
    end

    def accept
      @na = GediMigrationNA.find params[:id]
      authorize! :update, @na
      if params[:accept] == 'true'
        @na.accepted!
      else
        @na.rejected!
      end
      @na.save!
      render :json => {success: true}
    end

    def search(status)
      @search = GediMigrationNA.select(
          %{
            "gedi_migration_nas".*,
            "gedi_infraction_process_detran_ce_multa".id as multa_id
          }
        ).joins(
          { :associated_infraction => [:processes] },
          :infraction
        ).joins(
          %q{
            inner join gedi_infraction_process_detran_ce_multa 
              on gedi_infraction_process_detran_ce_multa.process_id = gedi_infraction_processes.id
          }
        ).where(
          status_id: status
        ).where(
          'associated is not null'
        ).order(
          "#{GediMigrationInfraction.table_name}.date"
        )
    end

    def generate
      @fines = []
      (search GediMigrationNA.accepts.accepted).all.each do |na|
        multa = Gedi::InfractionProcess::DetranCeMulta.find na.multa_id
        violator =multa.process.infraction.violator
        next if violator.vehicle.nil? || violator.violator.nil?
        @fines << (Gedi::InfractionFine.where(process_id: na.associated_infraction.processes.first.id).first || 
                   Gedi::InfractionFine.create(
                      process_id: multa.process_id,
                      docket_number: multa.codigo_de_barras,
                      value: multa.valor,
                      value_discount: multa.valor*0.8
                    )
                  )
      end
      authorize! :manage, GediMigrationNA
      respond_to do |format|
        format.html { render 'np' }
        format.pdf do 
          render 'np', :layout => false 

          pdf_name = "NP#{Date.today.strftime('%Y%m%d')}001.pdf"
          file_name = Rails.root.join('pdfs', pdf_name)
          #if !File.exist?(file_name)
            save_images_cache
            render  :pdf => pdf_name, 
                    :save_to_file => file_name, 
                    :template => 'gedi/nas/np', 
                    :page_size => 'A4', :page_height => '297mm', :page_width => '210mm', 
                    :margin => {
                      :top                => '15mm',                     # default 10 (mm)
                      :bottom             => '3mm',
                      :left               => '10mm',
                      :right              => '10mm'},
          #else
          #  send_file file_name, :stream=> false, :type => 'application/pdf', :disposition => 'inline'
          #end
        end
      end
    end

    def save_images_cache()
      FileUtils.mkdir(Rails.root.join("tmp", "images")) unless File.directory? Rails.root.join("tmp", "images")

      FileUtils.cp Rails.root.join("public", "assets", "images", "caixa.jpg"),      Rails.root.join("tmp", "images", "caixa.jpg")
      FileUtils.cp Rails.root.join("public", "assets", "images", "orgao.jpg"),      Rails.root.join("tmp", "images", "orgao.jpg")
      FileUtils.cp Rails.root.join("public", "assets", "images", "prefeitura.jpg"), Rails.root.join("tmp", "images", "prefeitura.jpg")
      FileUtils.cp Rails.root.join("public", "assets", "images", "correios.png"),   Rails.root.join("tmp", "images", "correios.png")
      
      @fines.each do |fine|
        fine.process.infraction.images.each do |image|
          puts_on_file Rails.root.join("tmp", "images", "#{image.id}.jpg"), image.image_data.data
        end
      end
    end

  end
end