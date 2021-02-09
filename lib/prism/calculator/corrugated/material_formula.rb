module Prism
  class Calculator::Corrugated::MaterialFormula
    include ActionView::Helpers::NumberHelper
    include Prism::ApplicationHelper
    attr_reader :error

    TRIMMING   = 20 # mm
    MAX_WIDTH  = 1_800 # mm
    MIN_WIDTH  = 900 # mm
    MAX_LENGTH = 2_600 # mm
    MAX_MATERIAL_LENGTH = 5_200 # mm

    def initialize(**params)
      @breakdown = params[:breakdown]
      @product   = params[:product]
      @partner   = params[:partner]
      @machine   = params[:machine]
      @paper     = params[:paper]
      @error     = nil
    end

    def product_price
      @product_price ||= @product.prices.find { |p| p[:partner] == @partner }
    end

    def material_ratecard
      Prism::PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'corrugated', 'components.id': @product.material&.id)
    end

    def material_tier
      material_ratecard.tiers.last
    end

    def price_per_meter
      material_tier.value
    end

    def width_adjuster(width)
      @adjusted_width = width * product_price[:impose_quantity]

      if @adjusted_width < MIN_WIDTH && @adjusted_width < MAX_WIDTH
        product_price[:impose_quantity] += 1
        width_adjuster(@adjusted_width)
      end

      @adjusted_width
    end

    def round_up(value)
      (value / 50.0).ceil * 50.0
    end

    def material_width
      @material_width ||= @product.width + @product.height + @product.fluting
    end

    def material_length
      @material_length ||= begin
        2 * (@product.width + @product.length) + @product.additional
      end
    end

    def material_width_used
      @material_width_used ||= begin
        width_used = width_adjuster(material_width)
        @product_price[:material_width_used] = width_used

        width_used
      end
    end

    def material_length_used
      @material_length_used = begin
        length_used = material_length
        @product_price[:material_length_used] = length_used

        length_used
      end
    end

    def material_width_actual
      @material_width_actual ||= begin
        width_actual = round_up(material_width_used + TRIMMING)
        @product_price[:material_width_actual] = width_actual

        width_actual
      end
    end

    def material_length_actual
      @material_length_actual ||= begin
        length_actual = material_length
        if material_length > MAX_LENGTH
          length_actual += @product.additional
        end

        @product_price[:material_length_actual] = length_actual
        length_actual
      end
    end

    def material_area
      @material_area ||= material_length_actual * material_width_actual
    end

    def box_price
      @box_price ||= material_area * price_per_meter / 1_000_000 / product_price[:impose_quantity]
    end

    def material_price
      @material_price ||= @product.quantity * box_price
    end

    def production_time
      product_price[:material_hour] = material_tier.production_time&.to_i || 0
    end

    def set_description
      product_price[:material_description] = <<~DESC
        Harga/meter2: <b>#{ idr price_per_meter }</b>
        Jml Produk Jadi: <b>#{ number @product.quantity }</b>
        Ukuran Produk: <b>#{ number @product.length }mm x #{ number @product.width }mm x #{ number @product.height }mm</b>

        <br /><b>BAHAN TERPAKAI:</b>
        Panjang Terpakai: <b>#{ number material_length_used }mm</b>
        Lebar Satuan: <b>#{ number material_width }mm</b>
        Lebar Terpakai: <b>#{ number material_width_used }mm</b>
        Pengali Lebar (Jumlah Mata): <b>#{ number product_price[:impose_quantity] }</b>

        <br /><b>AKTUAL BAHAN TERPAKAI:</b>
        Panjang Aktual: <b>#{ number material_length_actual }mm </b>
        Lebar Aktual: <b>#{ number material_width_actual }mm</b>

        <br />HARGA BOX: <b>#{ idr box_price }</b>
        TOTAL HARGA BOX: <b>#{ idr material_price }</b>
      DESC
    end

    def calculate
      if material_ratecard.blank? || @product.spec[:material].blank? || material_ratecard.deactive?
        @error = "[#{@product.printing_type}] Harga Material (#{@product.material&.name}) belum diisi atau Ukuran tidak dapat dihitung."
        @product.prices.reject! { |p| p[:partner] == @partner }
        return -1
      end

      if material_length > MAX_LENGTH || material_width > MAX_WIDTH
        @error = "[#{@product.printing_type}] Ukuran material tidak dapat dihitung."
        @product.prices.reject! { |p| p[:partner] == @partner }
        return -1
      end

      set_description
      product_price[:hours]           += production_time
      product_price[:material_price]  = material_price

      return material_price
    end
  end
end
