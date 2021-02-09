class KgToReamPriceOfficer

  attr_reader :price_per_kg, :width, :length, :gsm

  def initialize(price_per_kg, width_in_cm, length_in_cm, gsm)
    @price_per_kg = price_per_kg.to_f
    @width = width_in_cm.to_f
    @length = length_in_cm.to_f
    @gsm = gsm.to_f
  end

  def perform
    size_in_m2 = (width * length) / 10000
    weigth_per_ream = (size_in_m2 * gsm * 500) / 1000
    price_per_kg * weigth_per_ream
  end
end
