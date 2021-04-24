# == Schema Information
#
# Table name: provinces
#
#  id          :bigint(8)        not null, primary key
#  country_id  :bigint(8)
#  abbr        :string
#  name        :string
#  tags        :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  integration :jsonb
#

module Prism
  class Province < PrismModel
    acts_as_paranoid

    belongs_to :country
    has_many :cities

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      query = ActiveRecord::Base.connection.quote_string(query.strip)
      where('similarity(provinces.name, :query) >= 0.1 OR provinces.name % :query', query: query)
        .order(Arel.sql("similarity(provinces.name, '#{query}') DESC"))
    }

    scope :by_id, lambda { |id|
      return where(nil) if id.blank?

      where('provinces.id = ?', id)
    }

    def self.search(params = {})
      params = {} if params.blank?

      by_query(params[:query])
        .by_id(params[:id])
    end
  end
end
