# == Schema Information
#
# Table name: organization_financial_details
#
#  id                        :bigint(8)        not null, primary key
#  organization_id           :bigint(8)
#  npwp_number               :string
#  npwp_file                 :string
#  deleted_at                :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  npwp_address              :text
#  payment_term              :jsonb
#  invoice_term              :string
#  invoice_format            :jsonb
#  invoice_address_id        :bigint(8)
#  invoice_delivery_time     :jsonb
#  invoice_delivery_deadline :jsonb
#  invoice_delivery_document :text
#  invoice_delivery_note     :text
#  currency_code             :string
#  ktp_file                  :string
#  tdp_file                  :string
#  siup_file                 :string
#  ktp_number                :string
#  credit_limit              :float
#  business_name             :string
#  top_id                    :integer
#  top_terms                 :jsonb
#  tax_template              :boolean          default(FALSE)
#

module Prism
  class OrganizationFinancialDetail < PrismModel
    acts_as_paranoid

    # mount_uploader :npwp_file,  FileUploader
    # mount_uploader :ktp_file,   FileUploader
    # mount_uploader :tdp_file,   FileUploader
    # mount_uploader :siup_file,  FileUploader

    ASSESSABLE_COLUMNS = %w[
      payment_term invoice_term currency_code
      invoice_format invoice_address_id invoice_delivery_time invoice_delivery_deadline
      invoice_delivery_document invoice_delivery_note
    ].freeze

    INVOICE_TERMS = { 'Sebelum Produksi' => 'before_production', 'Sebelum Pengiriman' => 'before_delivery', 'Setelah Order Selesai' => 'after_order_completed' }.freeze
    PAYMENT_TERMS = { 'Hari Tetap' => 'fixed_day', 'Tanggal Tetap' => 'fixed_date', 'Hari Kerja Setelah' => 'workday_after', 'Hari Setelah' => 'day_after' }.freeze

    belongs_to :organization
    belongs_to :organization_address, foreign_key: :invoice_address_id, optional: true
    belongs_to :currency, class_name: 'Currency', primary_key: 'code', foreign_key: 'currency_code', optional: true

    def self.top_options
      Services::Finance::Term.select_options
    end

    def invoice_format_str
      str = 'Softcopy'
      str = 'Hardcopy' if invoice_format['hardcopy'] == 'true'
      str
    end

    def top_term
      top_terms.try(:[], 'name')
    end

    def default_payment_term
      payment_term.try(:[], 'code').try(:humanize)
    end

    def default_payment_term_value
      payment_term.try(:[], 'value').try(:to_i)
    end

    def default_payment_term_desc
      case payment_term.try(:[], 'code')
      when 'fixed_date'
        "Tanggal #{default_payment_term_value} setiap bulan"
      when 'fixed_day'
        "Setiap #{I18n.t(:"date.day_names", locale: :id)[payment_term['value']['day'].to_i]}, Minggu ke-#{payment_term['value']['week'].to_i}"
      when 'workday_after'
        "#{default_payment_term_value} hari kerja setelah invoice diterima"
      when 'day_after'
        "#{default_payment_term_value} hari kalender setelah invoice diterima"
      else
        '-'
      end
    end

    def invoice_delivery_time_desc
      begin
        days = invoice_delivery_time.first.try(:[], 'day')
        days = days.map{ |i| I18n.t(:"date.day_names", locale: :id)[i.to_i] } if !days.blank?
        time = invoice_delivery_time.first.try(:[], 'time')
        time = "(#{time})" if !time.blank?
        "#{days.join(',')} #{time}"
      rescue => e
        "-"
      end
    end

    def invoice_delivery_deadline_desc
      begin
        term = invoice_delivery_deadline["code"]
        value = invoice_delivery_deadline["value"]
        case term
        when 'fixed_date'
          "Tanggal Tetap (setiap tanggal #{value} setiap bulan)"
        when 'fixed_day'
          "Hari Tetap (setiap hari #{I18n.t(:"date.day_names", locale: :id)[value["day"].to_i]} minggu ke #{value["week"]})"
        end
      rescue => e
        "-"
      end
    end

    def physical_invoice
      invoice_format['hardcopy'] == 'true' ? 'Yes' : 'No'
    end

    def assessable_columns
      return ASSESSABLE_COLUMNS if Rails.env.test?
      organization.class == Company ?
        ASSESSABLE_COLUMNS + %w[npwp_number npwp_file npwp_address tdp_file siup_file].freeze :
        ASSESSABLE_COLUMNS + %w[ktp_file ktp_number].freeze
    end

    def is_complete?
      assessable_columns.all? {|attr| !send(attr).nil? }
    end

    def self.payment_terms_options
      PAYMENT_TERMS.map { |term| [term.humanize, term] }
    end
  end
end
