module Trail
  module Query
    # :nodoc:
    class Data
      property :selects
      property :joins
      property :wheres
      property :groups
      property :havings
      property :orders
      property :limit
      property :offset
      property :updates

      def dup
        Data.new.tap do |data|
          {% for attr in %w(selects joins wheres groups havings) %}
            if {{ attr.id }} = self.{{ attr.id }}
              data.{{ attr.id }} = {{ attr.id }}.dup if {{ attr.id }}.any?
            end
          {% end %}

          if orders = self.orders
            data.orders = orders.dup
          end

          data.limit = self.limit
          data.offset = self.offset
        end
      end
    end
  end
end
