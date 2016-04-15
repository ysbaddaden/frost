module Frost
  module Query
    # :nodoc:
    class Data
      property selects : Array(String)?
      property joins : Array(String)?
      property wheres : Array(String)?
      property groups : Array(String)?
      property havings : Array(String)?
      property orders : Hash(String, String)?
      property limit : Int32?
      property offset : Int32?

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
