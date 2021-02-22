# frozen_string_literal: true
# == Schema Information
#
# Table name: organizations
#
#  id                 :bigint(8)        not null, primary key
#  parent_id          :integer
#  type               :string
#  name               :string
#  website            :string
#  anniversary        :date
#  phone              :string
#  status             :integer
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  profile_completion :integer
#  lead_source_id     :integer
#  data               :jsonb
#  code               :string
#  integration        :jsonb
#  is_pro             :integer
#

require File.dirname(__FILE__) + '/organization.rb'

module Prism
  class Company < Organization
    SIZE = [
      %w[Small small],
      %w[Medium medium],
      %w[Large large]
    ].freeze

    TYPE = [].freeze

    has_many   :branches, class_name: 'Company', foreign_key: 'parent_id'
    belongs_to :head_quarter, class_name: 'Company', foreign_key: 'parent_id', optional: true

    delegate :legal_name, :industry_type, :company_size_info, to: :organization_detail, allow_nil: true
    delegate :invoice_format_str, to: :organization_financial_detail, allow_nil: true
  end
end
