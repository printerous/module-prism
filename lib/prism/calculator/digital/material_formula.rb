class Calculator::Digital::MaterialFormula
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
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
    @product_price ||= @product.prices.find { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
  end

  def material_ratecard
    PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @paper[:code], 'components.id': @product.material&.id)
  end

  def material_tier
    material_ratecard.tiers.last
  end

  def material_price
    product_price[:material_quantity] * price_per_sheet
  end

  def price_per_sheet
    material_tier.value
  end

  def production_time
    product_price[:material_hour] = material_tier.production_time&.to_i || 0
  end

  def print_area
    product_price[:impose_officer].paper
  end

  def set_description
    product_price[:material_description] = <<~DESC
      Jml Produk Jadi: <b>#{ number @product.quantity }</b>
      Ukuran Produk + Bleed: <b>#{ number @product.print_width }mm x #{ number @product.print_length }mm</b>
      Ukuran Material - Gripper: <b>#{ number print_area[:width] }mm x #{ number print_area[:length] }mm</b>
      Jml Muka/lembar material: <b>#{ number product_price[:impose_quantity] }</b>
      Jml Material: <b>#{ number product_price[:material_quantity] } lembar</b>
      Harga/lembar: <b>#{ idr price_per_sheet }</b>

      <br /><u>Perhitungan:</u>
      Jml Material * Harga/lembar
      <b>#{ number product_price[:material_quantity] } * #{ idr price_per_sheet }</b>
    DESC
  end

  def calculate
    if @product.material.blank? || material_ratecard.blank? || material_ratecard.deactive? || @product.spec[:material].blank?
      @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
      @error = "[#{@product.printing_type}] Harga Material (#{@product.material&.name}) belum diisi."
      return -1
    end

    set_description
    product_price[:hours]          += production_time
    product_price[:material_price] = material_price

    return material_price
  end
end
