# encoding: UTF-8
require "gedi/analysis/plate_query"
module Gedi
  class NasController < Gedi::BaseController
    load_and_authorize_resource :class => "GediMigrationNA", :except => [:list, :accept]

    def index
    end
    
    def list
      status = params[:status] || 0
      @search = GediMigrationNA.joins(:infraction).where(status_id: status).where('associated is not null').order("#{GediMigrationInfraction.table_name}.date")
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

  end
end