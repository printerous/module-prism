class Calculator::Corrugated::RubberCostFormula
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  attr_reader :error

  COMPONENT_CODE = 'RUBBER_COST_CORRUGATED'
  PRICE_LIMIT    = 200

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

  def component
    @component ||= Component.find_by(code: COMPONENT_CODE)
  end

  def rubber_ratecard
    PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, printing_type: 'corrugated', 'components.id': component&.id)
  end

  def rubber_tier
    rubber_ratecard.tiers.last
  end

  def rubber_length
    @rubber_length ||= if @product.print_area.present?
      @product.print_area[:length]
    else
      product_price[:material_length_used] / 10.to_f # in cm - FILLED ON MATERIAL FORMULA
    end
  end

  def rubber_width
    @rubber_width ||= if @product.print_area.present?
      @product.print_area[:width]
    else
      product_price[:material_width_used] / 10.to_f # in cm FILLED ON MATERIAL FORMULA
    end
  end

  def rubber_area
    @rubber_area ||= (rubber_length + 5) * (rubber_width + 5)
  end

  def rubber_price_actual
    @rubber_price_actual ||= rubber_tier.value * rubber_area * @product.print_color
  end

  def price_per_item
    @price_per_item ||= rubber_price_actual / @product.quantity.to_f
  end

  def rubber_price
    @rubber_price ||= if price_per_item < PRICE_LIMIT
      0
    else
      rubber_price_actual
    end
  end

  def production_time
    product_price[:rubber_cost_hour] = rubber_tier.production_time&.to_i || 0
  end

  def set_description
    product_price[:rubber_cost_description] = <<~DESC
      Panjang Area Cetak: <b>#{ number rubber_length, precision: 2 }cm</b>
      Lebar Area Cetak: <b>#{ number rubber_width, precision: 2 }cm</b>
      Luas Aktual Area Cetak: <b>#{ number rubber_area, precision: 2 }cm2</b>
      -- <i>Luas Aktual Area Cetak = (Panjang + 5 cm) * (Lebar + 5 cm)</i>

      <br/>Biaya Karet Cetak/cm2/warna: <b>#{ idr rubber_tier.value }</b>
      Harga Karet: <b>#{ idr rubber_price_actual }</b>
      Harga Karet / box: <b>#{ idr price_per_item }</b>

      <br/>Harga Karet Aktual / box: <b>#{ idr rubber_price / @product.quantity }</b> <i>(Gratis jika harga di bawah Rp200)</i>
      TOTAL HARGA BOX: <b>#{ idr rubber_price }</b>
    DESC
  end

  def calculate
    if rubber_ratecard.blank?
      @error = "[#{@product.printing_type}] Harga Rubber belum diisi."
      @product.prices.reject! { |p| p[:partner] == @partner }
      return -1
    end

    set_description
    product_price[:hours]            += production_time
    product_price[:rubber_cost_price] = rubber_price

    return rubber_price
  end
end