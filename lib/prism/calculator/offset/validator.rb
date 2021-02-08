class Calculator::Offset::Validator

  A3_LENGTH        = 297
  A3_WIDTH         = 420
  MINIMUM_MATERIAL = 500

  def initialize(width, length, quantity)
    @width    = width.to_f
    @length   = length.to_f
    @quantity = quantity.to_i
  end

  def offset?
    return false if [ @width, @length, @quantity ].any?(0)
    return false if bigger_than_a3? && @quantity < MINIMUM_MATERIAL

    material_quantity >= MINIMUM_MATERIAL
  end

  def valid_keys?(item_spec_ids, code)
    calculator = Prism::ProductCalculator.find_by(code: code)
    return false if calculator.blank?

    allowed_keys = calculator.allowed_keys.sort
    (allowed_keys & item_spec_ids).sort == item_spec_ids.sort
  end

  # check offset size first. if requested size bigger than offset size,  then definetely offset type
  def bigger_than_a3?
    (@width > A3_WIDTH || @width > A3_LENGTH) ||
    (@length > A3_WIDTH || @length > A3_LENGTH) ||
    (@width > A3_WIDTH && @length > A3_LENGTH)
  end

  # if size below offset size, calculate material quantity
  def material_quantity
    (@quantity / impose_quantity).ceil rescue 0
  end

  def impose_quantity
    return 1 if bigger_than_a3?
    [
      ((A3_WIDTH.to_f / @width.to_f).floor * (A3_LENGTH.to_f / @length.to_f).floor),
      ((A3_WIDTH.to_f / @length.to_f).floor * (A3_LENGTH.to_f / @width.to_f).floor)
    ].max
  end
end
