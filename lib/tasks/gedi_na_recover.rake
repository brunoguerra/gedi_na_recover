require 'docsplit'
require 'fileutils'

namespace :gedi_na_recover do
  desc 'recover NAs'
  task :recover => :environment do
    Time.zone = -3
    NADocument.nas_on_dir.each do |document|
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
          document_converter = NADocument.new(document)
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

class NADocument
  NA_PROCESSING_PATH = 'na/processing/'

  def self.nas_on_dir
    Dir[ENV['ATLANTA_IMPORT']+'nas/*.pdf']
  end

  def self.na_completed(file)
    file_name = file.split('/').last
    FileUtils.makedirs ENV['ATLANTA_IMPORT']+'nas-completed/'
    FileUtils.mv(file, ENV['ATLANTA_IMPORT']+'nas-completed/'+file_name)
  end

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
    @na_numbers = {}
    @pages    = 0
    first     = Dir[NA_PROCESSING_PATH+'text/*.txt'].first
    first     =~ /(\d*)_(\d*)(.txt)/i
    doc_num   = $1
    doc_digit = $2
    doc_ext   = $3
    s_find    = "#{doc_num}_#{doc_digit}#{doc_ext}"

    NADocument.nas_on_dir.each do |f|
      f =~ /(\d+)/
      @na_numbers.merge!( { $1.to_i => f } ) 
    end

    @na_numbers.sort_by { |number, file| number }.each do |na_number, na_file|
      inc       = 1
      current_file = lambda { first.gsub(s_find, "#{na_number}_#{inc}#{doc_ext}") }
      while File.exist?(current_file.call)
        decode_page(current_file.call)
        @facepage = !@facepage
        @pages += 1
        if (@pages % 2) == 0
          process_document(@page_decoded)
        end
        inc += 1
      end
      NADocument.na_completed(na_file)
      inc = 0
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
    #Docsplit.extract _ images(file, :output => NA_PROCESSING_PATH+'images/', :size => '752x', :format => [:png, :jpg])  
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


        @block_lines[0] =~ /Destinat.rio: (.*) Endere.o Propriet.rio: (.*) CEP: ([0-9\-\.]*) ,(.*) - (.*) Cidade - UF: (.*) - (.*)/i
        @violator[:name]    = $1
        @address[:desc]     = $2

        @address[:postal]  = $3
        @address[:number]   = $4
        @address[:district] = $5
        @address[:city]     = $6
        @address[:state]    = $7

    else
      @na         ||= {}
      @infraction ||= {}
      @vehicle    ||= {}
      @equipment  ||= {}
      
        @block_lines[1] =~ /Emitido em: (.*)/i 
        @na[:emission] = $1

        @block_lines[2] =~ /Auto de Infra..o: (S[0-9]*) Data da Infra..o: (.*) Local da Infra..o: (.*). Hora da Infra..o: (.*) Placa: (.*) Marca \/ Modelo: (.*) BASE LEGAL .* ESP.CIE: (.*) GRAVIDADE DA INFRA..O: .*/i 
        @na[:number] = $1
        @infraction[:date] = $2+" "
        @equipment[:local] = $3
        @infraction[:date] += $4
        @vehicle[:plate] = $5
        @vehicle[:mark_model] = $6
        @vehicle[:specie] = $7


        @block_lines[3] =~ /CPF \/ CNPJ do Propriet.rio: (\d*) C.d. da Infra..o: (\d*) Descri..o da Infra..o:/i 
        @violator[:doc] = $1
        @infraction[:code] = $2

        @block_lines[4] =~ /Desdobramento: (\d*)/i
        @infraction[:variant] = $1

        @block_lines[5] =~ /Vel. Considerada \(Km\/h\): (.*) Data Verifica..o do Equip.: (.*) Vel. Aferida \(Km\/h\): (.*) N. Lacre Inmetro: (.*) Cod. Equipamento: (.*) Mat. do Agente Autuador:/i
        @infraction[:speed_legal]     = $1
        @infraction[:speed_computed]  = $3
        @equipment[:code]             = $5

        @block_lines[9] =~ /([0-9A-Z\-]*)/i
        raise "Error parsing document #{@file}. Vehicle Plate not match #{@vehicle[:plate]} != #{$1}\n#{self.to_yaml}" if @vehicle[:plate] != $1

        @block_lines[10] =~ /([0-9]*)/i
        raise "Error parsing document #{@file}. Infraction Code not match #{@infraction[:code]} != #{$1}\n#{self.to_yaml}" if @infraction[:code] != $1

        @block_lines[13] =~ /(S[0-9]*)/i
        raise "Error parsing document #{@file}. NA Number not match #{@na[:number]} != #{$1}" if @na[:number] != $1

    end
      rescue Exception => e
        puts e.message
        Rails.logger.error "Invalid block line: #{print_block_line} #{@na.to_yaml} #{@infraction.to_yaml} #{@vehicle.to_yaml} #{@violator.to_yaml} #{@address.to_yaml} #{@equipment.to_yaml} \n #{e.message} \n\n #{e.backtrace}"
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
    begin
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
    rescue Exception => e
      Rails.logger.error  "#{e.message} \n\n #{e.backtrace}\n"
    end
  end
end