require "./formatter"
require "./data"

module Frost
  module Query
    class Builder
      include Formatter

      # :nodoc:
      getter data : Data

      def initialize(@table_name : String, @adapter, data : Data? = nil)
        @data = data || Data.new
      end

      def select(*columns)
        dup do |data|
          data.selects = if selects = data.selects
                           selects + columns.map(&.to_s).to_a
                         else
                           columns.map(&.to_s).to_a
                         end
        end
      end

      {% for name in %w(join where having) %}
        def {{ name.id }}(conditions : String, *params)
          dup.{{ name.id }}!(conditions, params)
        end

        {% unless name == "join" %}
          def {{ name.id }}(conditions : Hash)
            if conditions.empty?
              self
            else
              dup.{{ name.id }}!(conditions)
            end
          end
        {% end %}

        protected def {{ name.id }}!(conditions : Hash)
          if conditions.empty?
            self
          else
            {{ name.id }}!(flatten_conditions_hash(conditions), nil)
          end
        end

        protected def {{ name.id }}!(conditions : String, params)
          if params
            conditions = replace_placeholders(conditions, params)
          end

          if conds = data.{{ name.id }}s
            conds << conditions
          else
            data.{{ name.id }}s = [conditions]
          end

          self
        end
      {% end %}

      private def replace_placeholders(conditions, params)
        pos = prev = index = -1

        String.build do |str|
          while pos = conditions.index("?", prev + 1)
            if conditions[pos - 1] == '\\'
              str << conditions[(prev + 1) ... (pos - 1)] << "? "
              prev = pos + 1
            else
              str << conditions[(prev + 1) ... pos]
              str << escape_value(params[index += 1])
              prev = pos
            end
          end

          str << conditions[(prev + 1) .. -1]
        end
      end

      private def flatten_conditions_hash(conditions : Hash)
        conds = [] of String

        conditions.each do |key, value|
          key = key.to_s

          if value.is_a?(Hash)
            value.each do |k, v|
              conds << to_condition_s(with_table_name(k.to_s, key), v)
            end
          else
            conds << to_condition_s(with_table_name(key), value)
          end
        end

        conds.join(" AND ")
      end

      def group(*columns)
        dup do |data|
          data.groups = if groups = data.groups
                          groups + columns.map(&.to_s).to_a
                        else
                          columns.map(&.to_s).to_a
                        end
        end
      end

      def order(column : Symbol | String, direction = :asc)
        order({ column => direction })
      end

      def order(columns : Hash)
        dup do |data|
          orders = data.orders ||= {} of String => String

          columns.each do |column, direction|
            direction = direction.to_s.downcase == "asc" ? "ASC" : "DESC"
            orders[column.to_s] = direction
          end
        end
      end

      def reorder(column : Symbol | String, direction = :asc)
        reorder({ column => direction })
      end

      def reorder(columns : Hash)
        dup do |data|
          if orders = data.orders
            orders.clear
          else
            orders = data.orders = {} of String => String
          end

          columns.each do |column, direction|
            direction = direction.to_s.downcase == "asc" ? "ASC" : "DESC"
            orders[column.to_s] = direction
          end
        end
      end

      def limit(limit, offset = nil)
        dup do |data|
          data.limit = limit.to_i
          data.offset = offset && offset.to_i
        end
      end

      def dup
        dup.tap { |query| yield query.data }
      end

      def dup
        self.class.new(@table_name, adapter, data.dup)
      end

      private def adapter
        @adapter
      end

      private def with_table_name(column_name : String, table_name = @table_name)
        if column_name.index(".")
          adapter.quote(column_name)
        else
          "#{ adapter.quote(table_name) }.#{ adapter.quote(column_name) }"
        end
      end

      private def escape_value(value)
        if value.is_a?(Array)
          value.map { |v| adapter.escape(v) }.join(", ")
        else
          adapter.escape(value)
        end
      end

      private def to_condition_s(column, value)
        if value.is_a?(Array)
          "#{ column } IN (#{ escape_value(value) })"
        else
          "#{ column } = #{ adapter.escape(value) }"
        end
      end
    end
  end
end
