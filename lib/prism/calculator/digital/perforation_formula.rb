class Calculator::Digital::PerforationFormula < Calculator::Digital::PostPressFormula
  def price
    @price ||= ratecard.price_minimum + (additional_quantity * tier.price)
  end

  def quantity_minimum
    tier.quantity_bottom || 0
  end

  def additional_quantity
    [product_price[:material_quantity] - quantity_minimum, 0].max
  end

  def production_time
    product_price[:perforation_hour] = begin
      speed = ratecard.properties['production_speed']&.to_f
      product_price[:material_quantity] / speed
    rescue
      0
    end
  end

  def set_description
    product_price[:perforation_description] = <<~DESC
      Jumlah Material: <b>#{ number product_price[:material_quantity] }</b>
      Biaya Minimum: <b>#{ idr ratecard.price_minimum }</b>
      Quantity Minimum: <b>#{ number quantity_minimum }</b>
      Quantity Tambahan (Jumlah Material - Quantity Minimum): <b>#{ number additional_quantity }</b>
      Biaya Perforasi: <b>#{ idr tier.price }</b>

      <br />Perhitungan:
      Minimum Price + (Quantity Tambahan * Biaya Perforasi)
      <b>#{ idr ratecard.price_minimum } + (#{ number additional_quantity } * #{ idr tier.price })</b>
    DESC
  end

  def calculate
    is_none = ['NONE', 'NO'].include?(@product.spec[:perforation]&.to_s&.upcase&.strip)
    if @product.spec[:perforation].blank? || is_none
      return 0
    end

    if @product.spec[:perforation].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
      @error = "[#{@product.printing_type}] Harga Perforasi belum diisi."
      @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
      return -1
    end

    set_description

    product_price[:hours]            += production_time
    product_price[:perforation_price] = price
  end
end
