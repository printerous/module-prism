class Calculator::Digital::DoubleTapeFormula < Calculator::Digital::PostPressFormula
  COMPONENT_CODE = 'DOUBLE_TAPE'

  def component
    @component ||= Component.find_by(code: self.class::COMPONENT_CODE)
  end

  def double_tape_count
    @double_tape_count ||= if (1..10).include?(@product.spec[:double_tape]&.to_i)
      @product.spec[:double_tape]&.to_i
    else
      spec_value = SpecValue.find_by(id: @product.spec[:double_tape])
      spec_value.properties['value'] || spec_value.name&.to_i
    end || 1
  end

  def price
    @price ||= @product.quantity * double_tape_count * tier.price
  end

  def production_time
    product_price[:double_tape_hour] = begin
      speed = ratecard.properties['production_speed']&.to_f
      @product.quantity / speed * 1
    rescue
      0
    end
  end

  def set_description
    product_price[:double_tape_description] = <<~DESC
      Jumlah Produk: <b>#{ number @product.quantity }</b>
      Jumlah Double Tape: <b>#{ number double_tape_count }</b>
      Biaya Double Tape: <b>#{ idr tier.price }/produk</b>

      <br />Perhitungan:
      Quantity * Jumlah Double Tape * Biaya Double Tape
      <b>#{ number @product.quantity } * #{ number double_tape_count } * #{ idr tier.price }</b>
    DESC
  end

  def calculate
    is_none = %w[NONE 972].include?(@product.spec[:double_tape]&.to_s&.upcase&.strip)
    if @product.spec[:double_tape].blank? || @product.spec[:double_tape].try(:to_i) == 0 || is_none
      return 0
    end

    if @product.spec[:double_tape].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
      @error = "[#{@product.printing_type}] Harga Double Tape belum diisi."
      @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
      return -1
    end

    set_description

    product_price[:hours]            += production_time
    product_price[:double_tape_price] = price
  end
end
