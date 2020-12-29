module Prism
  class PrismModel < ActiveRecord::Base
    establish_connection(
      adapter: :postgresql,
      host: ENV['PRISM_DBHOST'],
      port: ENV['PRISM_DBPORT'],
      username: ENV['PRISM_DBUSER'],
      password: ENV['PRISM_DBPASS'],
      database: ENV['PRISM_DBNAME']
    )

    self.abstract_class = true

    class << self
      def find_sti_class(type_name)
        type_name = name
        super
      end

      def sti_name
        name.split('::').last
      end
    end
  end
end
