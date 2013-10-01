module Gedi
  module NaRecover
    class Engine < ::Rails::Engine
      isolate_namespace Gedi
      engine_name 'gedi_na_recover'
      
      #TODO Initialize rspec_paths
      #config.rspec_paths << self.root

      config.to_prepare do
        #loads application's model / class decorators
        Dir[File.expand_path('../../../../app/**/*_decorator*.rb', __FILE__)].each do |c|
          Rails.application.config.cache_classes ? require(c) : load(c)
        end
      end

      
      initializer "gedi.activeadmin" do |config|
        ActiveAdmin.application.load_paths += Dir[File.dirname(__FILE__) + '/../../../app/admin']
      end
      
      initializer 'guara.menu.gedi.na_recover.items' do |config|
        Guara::Menus::MODULES[:modules][:items][1][:items] <<  
          { name: :gedi_migration_na_recover, resource: GediMigrationNA, path: "gedi.nas_path()" }
        #Guara::Menus::MAINTENCE[:items] += [ { name: :gedi_, resource: Gedi::NaRecover:: path: "guara.maintence_gedi_na_recover_xxx_path()" } ]
      end
    
      config.generators do |g|
        g.test_framework :rspec
        g.integration_tool :rspec
      end
      
      initializer "gedi.gedi.assets" do |config|
        config.assets.paths << Rails.root.join("app", "assets", "stylesheet", "gedi")
      end
    
    end
  end
end

Dir[File.expand_path("../dependencies/*.rb", __FILE__)].each {|f| require f; }
