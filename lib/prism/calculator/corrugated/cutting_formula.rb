class Calculator::Corrugated::CuttingFormula
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  attr_reader :error

  MINIMUM_LENGTH = 700 # in mm
  MINIMUM_WIDTH  = 320 # in mm

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

  def component_manual
    @component_manual ||= Component.find_by(code: 'CUTTING_CORRUGATED_MANUAL')
  end

  def cutting_ratecard_manual
    PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, printing_type: 'corrugated', 'components.id': component_manual&.id)
  end

  def cutting_tier_manual
    cutting_ratecard_manual.tiers.last
  end

  def component_auto
    @component_auto ||= Component.find_by(code: 'CUTTING_CORRUGATED_AUTO')
  end

  def cutting_ratecard_auto
    PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, printing_type: 'corrugated', 'components.id': component_auto&.id)
  end

  def cutting_tier_auto
    cutting_ratecard_auto.tiers.last
  end

  def minimum_auto
    cutting_tier_auto.quantity_bottom || 20_000
  end

  def cutting_tier
    @cutting_tier ||= if @product.quantity >= minimum_auto
      cutting_tier_auto
    else
      cutting_tier_manual
    end
  end

  def cutting_length
    # 4 * panjang + 16 * tinggi + 6 * lebar + 6 * flutting (single atau double) + 2 * kuping (single atau double) + (2 * kuping lagi (single atau double) kalo panjang aktual > 260)
    @cutting_length ||= begin
      length = (4 * @product.length) + (16 * @product.height) + (6 * @product.width) + (6 * @product.fluting) + (2 * @product.additional)

      if product_price[:material_length_used] > Calculator::Corrugated::MaterialFormula::MAX_LENGTH
        length += 2 * @product.additional
      end

      length / 10.to_f
    end
  end

  def cutting_price_each
    cutting_tier.value
  end

  def cutting_price
    return 0 if free_cutting?

    @cutting_price ||= cutting_price_each * cutting_length
  end

  def free_cutting?
    product_price[:material_length_used] > MINIMUM_LENGTH && product_price[:material_width_used] > MINIMUM_WIDTH
  end

  def kisscut_type
    return 'Otomatis' if @product.quantity >= minimum_auto

    'Manual'
  end

  def production_time
    product_price[:cutting_hour] = cutting_tier.production_time&.to_i || 0
  end

  def set_description
    product_price[:cutting_description] = <<~DESC
      Panjang Bahan Terpakai: <b>#{ number product_price[:material_length_used] / 10.to_f, precision: 2 }cm</b>
      Lebar Bahan Terpakai: <b>#{ number product_price[:material_width_used] / 10.to_f, precision: 2 }cm</b>
      Panjang Keliling Potong: <b>#{ number cutting_length, precision: 2 }cm</b>
      Harga Pisau (#{ kisscut_type }): <b>#{ idr cutting_price_each }</b>/cm

      <br/>TOTAL HARGA PISAU: <b>#{ idr cutting_price }</b>
      -- <i>Jika ukuran terbuka lebih besar dari 70cm x 30cm, maka FREE</i>
    DESC
  end

  def calculate
    if cutting_ratecard_manual.blank? || cutting_ratecard_auto.blank?
      @error = "[#{@product.printing_type}] Harga Cutting belum diisi."
      @product.prices.reject! {|p| p[:partner] == @partner }
      return -1
    end

    set_description
    product_price[:hours]        += production_time
    product_price[:cutting_price] = cutting_price

    return cutting_price
  end
end