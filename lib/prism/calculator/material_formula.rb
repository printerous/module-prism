module Prism
  class Calculator::MaterialFormula
    include ActionView::Helpers::NumberHelper
    include Prism::ApplicationHelper
    attr_reader :error

    def initialize(**params)
      @breakdown = params[:breakdown]
      @product   = params[:product]
      @partner   = params[:partner]
      @machine   = params[:machine]
      @paper     = params[:paper]
      @error     = nil
    end

    def product_price
      @product_price ||= @product.prices.find {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
    end

    def material_ratecard
      PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @paper.plano.code, 'components.id': @product.material.id)
    end

    def material_tier
      material_ratecard.tiers.last
    end

    def paper_weight
      @paper.weight(@product.material.properties['gsm'].try(:to_f))
    end

    def material_weight
      paper_weight * product_price[:material_quantity]
    end

    def material_price
      total_material_weight * price_per_kg
    end

    def price_per_kg
      gsm =  @product.material.properties['gsm'].try(:to_f)
      plano = @paper.plano
      KgToReamPriceOfficer.new(material_tier.value, (plano.width/10), (plano.length/10), gsm).perform
    end

    def waste_quantity
      product_price[:waste_quantity]
    end

    def waste_weight
      paper_weight * waste_quantity
    end

    def total_material_quantity
      product_price[:total_material_quantity] = product_price[:material_quantity] + waste_quantity
    end

    def total_material_weight
      product_price[:total_material_weight] = material_weight + waste_weight
    end

    def production_time
      product_price[:material_hour] = material_tier.production_time&.to_i || 0
    end

    def set_description
      product_price[:material_description] = <<~DESC
        Jml Produk Jadi: <b>#{ number @product.quantity }</b>
        Ukuran Produk + Bleed: <b>#{ number @product.print_width }mm x #{ number @product.print_length }mm</b>
        Ukuran Material - Gripper: <b>#{ number product_price[:paper_width] }mm x #{ number product_price[:paper_length] }mm</b>
        Jml Muka/lembar material: <b>#{ number product_price[:impose_quantity] }</b>
        Jml Material: <b>#{ number product_price[:material_quantity] } lembar (#{ number_decimal material_weight }kg)</b>
        Jml Waste atau Insheet: <b>#{ number waste_quantity } lembar (#{ number_decimal waste_weight }kg)</b>
        Total Material: <b>#{ number total_material_quantity } lembar  (#{ number_decimal total_material_weight }kg)</b>
        Harga/kg: <b>#{ idr price_per_kg }</b>

        <br /><u>Perhitungan:</u>
        Total Berat Material * Harga/kg
        <b>#{ number_decimal total_material_weight }kg * #{ idr price_per_kg }</b>
      DESC
    end

    def calculate
      if @product.material.blank? || material_ratecard.blank? || @product.spec[:material].blank? || material_ratecard.deactive?
        @error = "[#{@product.printing_type}] Harga Material (#{@product.material&.name}) belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]           += production_time
      product_price[:waste_weight]    = waste_weight
      product_price[:waste_quantity]  = waste_quantity
      product_price[:material_weight] = material_weight
      product_price[:material_price]  = material_price

      return material_price
    end
  end

end
