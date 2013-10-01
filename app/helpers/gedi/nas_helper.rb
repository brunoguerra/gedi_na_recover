module Gedi
  module NasHelper
    def order_by?(field)
      order_asc_icon(params[:order][:asc]=="+") if (!params[:order].nil?) && params[:order][:field]==field;
    end
  end
end