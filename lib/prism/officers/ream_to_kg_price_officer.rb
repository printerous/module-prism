# frozen_string_literal: true

class ReamToKgPriceOfficer
  attr_reader :price_per_ream, :width, :length, :gsm

  def initialize(price_per_ream, width_in_cm, length_in_cm, gsm)
    @price_per_ream = price_per_ream.to_f
    @width          = width_in_cm.to_f
    @length         = length_in_cm.to_f
    @gsm            = gsm.to_f
  end

  def perform
    size_in_m2      = (width * length) / 10000
    weigth_per_ream = (size_in_m2 * gsm * 500) / 1000
    price_per_ream / weigth_per_ream
  end
end
