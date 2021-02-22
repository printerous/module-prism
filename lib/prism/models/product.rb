# == Schema Information
#
# Table name: products
#
#  id                  :bigint(8)        not null, primary key
#  product_type_id     :bigint(8)
#  code                :string
#  name                :string
#  spec                :jsonb
#  deleted_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  data                :jsonb
#  tags                :string
#  inquiry_items_count :integer
#  standard_at         :datetime
#

module Prism
  class Product < PrismModel
    acts_as_paranoid

    belongs_to :product_type
    has_many :product_prices

    scope :by_spec_id, lambda { |spec_id|
      return where(nil) if spec_id.blank?

      where("products.data -> 'spec_id' = ?", spec_id.to_json)
    }

    scope :by_custom_size, lambda { |custom_size|
      return where(nil) if custom_size.blank?

      where("products.data ? 'size'")
        .where("products.data -> 'size' ->> 'width' = ?", custom_size[:width]&.to_s)
        .where("products.data -> 'size' ->> 'length' = ?", custom_size[:length]&.to_s)
    }

    def _spec
      return {} if data.nil?

      data['spec_id'].with_indifferent_access
    end
    alias_method :spec_id, :_spec

    def spec_string
      spec.map { |k, v| "#{k}: #{v}" }.join(', ')
    end

    def printside
      side = 1
      spec_id.each do |spec_key_id, value|
        spec_key = SpecKey.find_by(id: spec_key_id)
        spec_value = SpecValue.find_by(id: value)

        side = spec_value.properties['side'].to_i if spec_key.code == 'printside'
      end

      side
    end

    def size_in_mm
      if custom_size?
        size = data['size']&.with_indifferent_access || {}
      else
        spec = spec_id.find do |k, _v|
          spec_key = SpecKey.find_by(id: k)
          spec_key.code == 'size' || spec_key.code == 'ukuranprodukjadi'
        end || []

        spec_value = SpecValue.find_by(id: spec[1])

        size = {
          width: (spec_value&.properties.try(:[], 'width_in_mm') || 0),
          length: (spec_value&.properties.try(:[], 'length_in_mm') || 0)
        }
      end

      size.map { |k, v| [k, v&.to_i] }&.to_h&.with_indifferent_access
    end

    def width_in_mm
      size_in_mm[:width]
    end

    def length_in_mm
      size_in_mm[:length]
    end
    alias height_in_mm length_in_mm

    def width
      size_in_mm[:width] / 10.0
    rescue StandardError
      0
    end

    def length
      size_in_mm[:length] / 10.0
    rescue StandardError
      0
    end
    alias height length

    def width_in_pixels
      (size_in_mm[:width].to_f / 25.4 * 300).to_i
    end

    def length_in_pixels
      (size_in_mm[:length].to_f / 25.4 * 300).to_i
    end
    alias height_in_pixels length_in_pixels

    def custom_size?
      data['spec_id']&.values&.find { |v| SpecValue.find_by(id: v)&.code == 'CUSTOM_SIZE' }&.present?
    end

    def tshirt_size
      open_id       = SpecKey.find_by(code: 'size')&.id&.to_s
      closed_id     = SpecKey.find_by(code: 'ukuranprodukjadi')&.id&.to_s

      spec_value_id = spec_id[open_id] || spec_id[closed_id]
      spec_value    = SpecValue.find_by id: spec_value_id
      spec_value&.name
    end

    def size_in_string
      if custom_size?
        "CUSTOM SIZE (#{length}cm x #{width}cm)"
      else
        "#{length}cm x #{width}cm"
      end
    end

    def weight
      data['weight'] || 0
    end

    def volume
      data['volume'] || 0
    end

    def dimension
      {
        width: width_in_mm,
        length: length_in_mm
      }
    end
  end
end
