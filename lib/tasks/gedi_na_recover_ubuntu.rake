# encoding: utf-8
require 'docsplit'

namespace :gedi_na_recover_ubuntu do
  desc 'recover NAs'
  task :recover => :environment do
    Time.zone = -3
    Dir[ENV['ATLANTA_IMPORT']+'nas/*.pdf'].each do |document|
      puts 'Converting '+document
      document = NADocument.new(document)
      document.convert
    end
  end
  namespace :utils do
    desc 'processing pre-data NAs'
    task :process => :environment do
      Time.zone = -3
      Dir['na/processing/text/*.txt'].each do |document|
        puts 'Converting '+document
        begin
          document_converter = Ubuntu::NADocument.new(document)
          document_converter.process
        rescue Exception => e
          puts "error on importing #{document}"
          puts e.to_yaml
          puts "\n\n"
          puts e.backtrace
        end
        break
      end
    end
  end

end

###############################################################################################################
#                             Document NA
###############################################################################################################
module Ubuntu
  class NADocument

    NA_PROCESSING_PATH = 'na/processing/'

    def initialize(document)
      @file = document
      @facepage = true
    end

    #receives a txt page
    def decode_page(page)
      if @facepage
        @page_decoded = Facepage.new(page)
        @page_decoded.decode_frontpage
      else
        @page_decoded.decode_backface(page)
      end
    end

    def convert
      NADocument.split_pages(@file)
      convert_pages
      process
    end

    def process
      @pages = 0
      first = Dir[NA_PROCESSING_PATH+'text/*.txt'].first
      first =~ /(\d*)(.txt)/i
      doc_digit = $1
      doc_ext   = $2
      s_find    = doc_digit+doc_ext
      inc       = 1

      while File.exist?(first.gsub(s_find, inc.to_s+doc_ext))
        f = first.gsub(s_find, inc.to_s+doc_ext)
        decode_page(f)
        @facepage = !@facepage
        @pages += 1
        if (@pages % 2) == 0
          process_document(@page_decoded)
        end
        inc += 1
      end
    end

    def process_document(facepage)
      @ducument_processed = DocumentToDatabase.new(facepage).save
    end

    def convert_pages
      Dir[NA_PROCESSING_PATH+'pages/*.pdf'].each do|f|
        convert_file f
      end
    end

    def convert_file(file)
      NADocument.extranct_text(file)
    end

    def self.extranct_text(file)
      Docsplit.extract_text(file, :output => NA_PROCESSING_PATH+'text/')  
    end

    def self.extranct_images(file)
      #Docsplit.extract_images(file, :output => NA_PROCESSING_PATH+'images/', :size => '752x', :format => [:png, :jpg])  
    end

    def self.split_pages(file)
      Docsplit.extract_pages(file, :output => NA_PROCESSING_PATH+'pages/')
    end

  end

  ###############################################################################################################
  #                             Facepage
  ###############################################################################################################
  class Facepage

    attr_accessor :file, :violator, :address, :equipment, :infraction, :vehicle, :na

    def initialize(file)
      @file = file
      @block_lines = []
      @buffer_block = ''
      @na = { :reference => @file }
    end

    def decode_frontpage
      @frontpage = true
      decode
    end

    def decode
      puts "reading #{@file}"
      File.open(@file, 'r') do |f|
        f.each_line do |line|
          if line.strip == ''
            add_block
          else
            add_buffer line
          end
        end
      end

      extract_fields
    end

    def add_buffer(content)
      @buffer_block += content
    end

    def add_block
      @block_lines << @buffer_block
      @buffer_block = ''
    end

    def clear_block
      @block_lines_last = @block_lines
      @block_lines = []
    end

    def extract_fields
      begin
        if @frontpage
          @violator = {}
          @address  = {}

          @block_lines[0] =~ /Destinat\xC3\xA1rio:\n\s*(.*)/im
          @violator[:name]    = ($1).to_s.strip

          @block_lines[2] =~ /Endere\xC3\xA7o Propriet\xC3\xA1rio:[\n\s]*(.*)\s*CEP:\n\s*([0-9\-]*)/im
          @address[:desc]    = ($1).to_s.strip
          @address[:postal]  = ($2).to_s.strip

          @block_lines[3] =~ /, (.*) - (.*)/im
          @address[:number]   = ($1).to_s.strip
          @address[:district] = ($2).to_s.strip
          @block_lines[15] =~ /Cidade - UF:\n\s*(.*) - (.*)/im
          @address[:city]     = ($1).to_s.strip
          @address[:state]    = ($2).to_s.strip
          #raise "empty data of violator" if @address[:state].to_s.empty?
        else
          @na         ||= {}
          @infraction ||= {}
          @vehicle    ||= {}
          @equipment  ||= {}

          @block_lines[1] =~ /Emitido em: (.*)/i 
          @na[:emission] = ($1).to_s.strip

          @block_lines[2] =~ /Auto de Infra\xC3\xA7\xC3\xA3o:.*(S[0-9]*)/im
          @na[:number] = $1
          @block_lines[3] =~ /Local da Infra..o:[\n\s]*([^\n]*)/im
          @equipment[:local] = ($1).to_s.strip
          #.Data da Infra..o:.(.*)..Hora da Infra..o:.(.*).Placa:.(.*).Marca \/ Modelo:.(.*).BASE LEGAL..*.ESP.CIE:.(.*).GRAVIDADE DA INFRA..O: .*/i

          #data e hora
          @block_lines[8] =~ /([0-9\/]*)/i
          @infraction[:date] = $1+" "
          @block_lines[9] =~ /([0-9\:]*)/i
          @infraction[:date] += $1

          @block_lines[10] =~ /([0-9A-z\-]*)/i
          @vehicle[:plate] = $1

          @block_lines[12] =~ /CPF \/ CNPJ do Propriet\xC3\xA1rio:\n(.*)/im
          @violator[:doc] = ($1).to_s.strip

          @block_lines[14] =~ /Marca \/ Modelo:.([A-z\/\\\-\.\s]*)/im
          @vehicle[:mark_model] = ($1).to_s.strip
          @block_lines[15] =~ /Esp\xC3\xA9cie:.([A-z\/\\\-\.\s]*)/im
          @vehicle[:specie] = ($1).to_s.strip

          @block_lines[21] =~ /(\d*)/im
          @infraction[:code] = ($1).to_s.strip

          @block_lines[22] =~ /(\d*)/im
          @infraction[:variant] = ($1).to_s.strip

          @block_lines[30] =~ /(\d*)/im
          @infraction[:speed_legal]     = ($1).to_s.strip.to_i

          @block_lines[32] =~ /(\d*)/im
          @infraction[:speed_computed]  = ($1).to_s.strip.to_i

          @block_lines[33] =~ /(ATSMS\d*)/im
          @equipment[:code]             = ($1).to_s.strip

          @block_lines[45] =~ /([0-9A-Z\-]*)/im
          raise "Error parsing document #{@file}. Vehicle Plate not match #{@vehicle[:plate]} != #{$1}\n#{self.to_yaml}" if @vehicle[:plate] != ($1).to_s.strip

          @block_lines[46] =~ /(\d*)/im
          raise "Error parsing document #{@file}. Infraction Code not match #{@infraction[:code]} != #{$1}\n#{self.to_yaml}" if @infraction[:code] != $1

          @block_lines[50] =~ /(S[0-9]*)/im
          raise "Error parsing document #{@file}. NA Number not match #{@na[:number]} != #{$1}" if @na[:number] != $1
        end
      rescue Exception => e
        puts e.message
        raise "Invalid block line: #{print_block_line} #{@na.to_yaml} #{@infraction.to_yaml} #{@vehicle.to_yaml} #{@violator.to_yaml} #{@address.to_yaml} #{@equipment.to_yaml}"
      end
    end

    def decode_backface(file)
      @file = file 
      @frontpage = false
      clear_block
      decode
    end

    def print_block_line
      res = ""
      i = 0
      @block_lines.each do |l|
        res += "#{i} - #{l.to_yaml}"
        i += 1
      end
      res
    end
  end

  ###############################################################################################################
  #                             DocumentToDatabase
  ###############################################################################################################

  class DocumentToDatabase
    def initialize(decoded)
      @decoded = decoded
    end

    def save
      GediMigrationViolator.transaction do
        if GediMigrationNA.where(number: @decoded.na[:number]).count==0
          @violator = GediMigrationViolator.create(@decoded.violator)

          @decoded.address[:violator_id] = @violator.id
          @address = GediMigrationViolatorAddress.create(@decoded.address)
          
          @decoded.vehicle[:violator_id] = @violator.id
          @vehicle = GediMigrationVehicle.create(@decoded.vehicle)

          @equipment = GediMigrationEquipment.find_by_code(@decoded.equipment[:code])
          @equipment = GediMigrationEquipment.create(@decoded.equipment) if @equipment.nil?

          @decoded.infraction[:violator_id] = @violator.id
          @decoded.infraction[:equipment_id] = @equipment.id
          @infraction = GediMigrationInfraction.create(@decoded.infraction)      

          @decoded.na[:infraction_id] = @infraction.id
          @na = GediMigrationNA.create(@decoded.na)
        end
      end
    end
  end
end
