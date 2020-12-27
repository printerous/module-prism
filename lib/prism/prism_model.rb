module Prism
  class PrismModel < ActiveRecord::Base
    establish_connection(
      adapter: :postgresql,
      host: ENV.fetch('PRISM_DBHOST'),
      port: ENV.fetch('PRISM_DBPORT'),
      username: ENV.fetch('PRISM_DBUSER'),
      password: ENV.fetch('PRISM_DBPASS'),
      database: ENV.fetch('PRISM_DBNAME')
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
