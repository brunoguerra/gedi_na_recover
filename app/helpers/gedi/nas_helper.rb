# encoding: utf-8
module Gedi
  module NasHelper
    def order_by?(field)
      order_asc_icon(params[:order][:asc]=="+") if (!params[:order].nil?) && params[:order][:field]==field;
    end

    def fines_barcode(code)
      require 'barby'
      #require 'barby/barcode/code_128'
      require 'barby/barcode/code_25_interleaved'
      require 'barby/outputter/svg_outputter'
      barcode = Barby::Code25Interleaved.new(code.strip)
    end

    def detran_infraction_code(code)
      code[0..-2]
    end

    def detran_infraction_desdobramento(code)
      code[-1..-1]
    end

    def fine_barcode_to_read(barcode)
      barcode[0..11]+' '+barcode[12..23]+' '+barcode[24..35]+' '+barcode[36..47]
    end

    def fine_barcode_to_read_doc(barcode)
      #barcode[0..4]+'.'+barcode[5..9]+' '+barcode[10..14]+'.'+barcode[15..19]+' '+barcode[20..24]+'.'+barcode[25..30]+' '+barcode[31]+' '+barcode[32..-1]
    end
  end
end