# frozen_string_literal: true

module Prism
  # #
  # This class is made to select the printing way method: BBL, BBS, BBL
  # BBL: Bulak Balik Lain
  # BBS: Bulak Balik Sama
  # BBB: Bulak Balik Bakul
  #
  # Params
  # gripper -> machine's gripper in mm
  # paper_width -> paper's width
  # paper_length -> paper's length
  # quantity -> product quantity (Float)
  # width -> product original width (Float)
  # length -> product original length (Float)

  class Calculator::PrintingModeOfficer
    BLEED = 3 # millimeter
    MODE  = {
      bbl: :BBL,
      bbs: :BBS,
      bbb: :BBB
    }.freeze

    def initialize(params = {})
      @gripper        = params[:gripper]
      @paper_length   = params[:paper_length]
      @paper_width    = params[:paper_width].to_f - @gripper.to_f

      @quantity       = params[:quantity]
      @width          = params[:width]
      @length         = params[:length]
      @print_side     = params[:print_side]
      @colors         = params[:colors]
      @lamination     = params[:lamination]
      @lamination_b   = params[:lamination_b]

      @product_length = @length.to_f + 2 * BLEED
      @product_width  = @width.to_f + 2 * BLEED
    end

    MODE.each do |k, v|
      define_method "#{k}?" do
        mode == v
      end

      define_method "#{v}?" do
        mode == v
      end
    end

    def impose_options
      @impose_options ||= [impose_landscape, impose_portrait]
    end

    def impose
      @impose ||= impose_options.max
    end

    def impose_landscape
      @impose_landscape ||= landscape_horizontal * landscape_vertical
    end

    def landscape_horizontal
      @landscape_horizontal ||= (@paper_length / @product_length).floor
    end

    def landscape_vertical
      @landscape_vertical ||= (@paper_width / @product_width).floor
    end

    def impose_portrait
      @impose_portrait ||= portrait_horizontal * portrait_vertical
    end

    def portrait_horizontal
      @portrait_horizontal ||= (@paper_length / @product_width).floor
    end

    def portrait_vertical
      @portrait_vertical ||= (@paper_width / @product_length).floor
    end

    def mode
      return @mode if @mode.present?

      return nil if @print_side == 1

      # Jika Ganjil ATAU beda jumlah warna depan-belakang ATAU beda laminasi depan-belakang
      return @mode = MODE[:bbl] if impose.odd? || !same_color? || !same_lamination?

      # Jika Genap
      if impose_landscape == impose_portrait && (landscape_horizontal.even? || portrait_horizontal.even?)
        return @mode = MODE[:bbs]
      end

      if (impose_landscape != impose_portrait) &&
         ((impose_options.index(impose) == 0 && landscape_horizontal.even?) || (impose_options.index(impose) == 1 && portrait_horizontal.even?))
        return @mode = MODE[:bbs]
      end

      # Impose Landscape/Portrait tapi Horizontal Ganjil
      # dan Vertical Genap
      if (
            (impose_options.index(impose) == 0 && landscape_horizontal.odd? && landscape_vertical.even?) ||
            (impose_options.index(impose) == 1 && portrait_horizontal.odd? && portrait_vertical.even?)
          ) && impose == impose_2
        return @mode = MODE[:bbb]
      end

      # Jika Landscape & Portrait keduanya Ganjil
      @mode = MODE[:bbl]
    end

    def impose_2
      @impose_2 ||= begin
        _paper_width = @paper_width - @gripper.to_f

        [
          (landscape_horizontal * (_paper_width / @product_width).floor),
          (portrait_horizontal * (_paper_width / @product_length).floor)
        ].max
      end
    end

    def impose_count
      BBB? ? impose_2 : impose
    end

    def paper_width
      if BBB?
        @paper_width - @gripper
      else
        @paper_width
      end
    end

    def plate_design
      if BBL?
        2
      else
        1
      end
    end

    def same_color?
      @print_side == 1 || @colors.uniq.size == 1
    end

    def same_lamination?
      @lamination == @lamination_b
    end
  end
end
