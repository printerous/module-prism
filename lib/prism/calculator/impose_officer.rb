# frozen_string_literal: true

module Prism
  ##
  # args
  # paper: { width: X, length: X }
  # product: { width: X, length: X }
  # bleed: --> DEFAULT is 4

  class Calculator::ImposeOfficer
    BLEED = 2
    attr_reader :paper, :product, :bleed

    def initialize(paper, product, **args)
      @options = { bleed: 2, gripper: 10 }.merge(args).with_indifferent_access

      @bleed   = @options[:bleed]
      @gripper = @options[:gripper]
      @paper   = {
        width: paper[:width] - @gripper,
        length: paper[:length] - @gripper
      }

      @product = {
        width: product[:width] + 2 * bleed,
        length: product[:length] + 2 * bleed
      }
    end

    def impose
      @impose ||= impose_options.max
    end

    def orientation
      return :landscape if impose_landscape >= impose_portrait

      :portrait
    end

    def landscape?
      orientation == :landscape
    end

    def portrait?
      orientation == :portrait
    end

    def impose_options
      @impose_options ||= [impose_landscape, impose_portrait]
    end

    def impose_landscape
      @impose_landscape ||= landscape_horizontal * landscape_vertical
    end

    def landscape_horizontal
      @landscape_horizontal ||= (paper[:length] / product[:length]).floor
    end

    def landscape_vertical
      @landscape_vertical ||= (paper[:width] / product[:width]).floor
    end

    def impose_portrait
      @impose_portrait ||= portrait_horizontal * portrait_vertical
    end

    def portrait_horizontal
      @portrait_horizontal ||= (paper[:length] / product[:width]).floor
    end

    def portrait_vertical
      @portrait_vertical ||= (paper[:width] / product[:length]).floor
    end
  end
end
