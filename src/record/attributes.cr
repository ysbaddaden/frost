require "../support/core_ext/string"
require "./connection"

module Frost
  abstract class Record
    class Attributes
      getter :class_name, :table

      def initialize(@class_name)
        @table = Record.connection do |conn|
          conn.table(@class_name.tableize)
        end
      end

      def generate_initialize(io)
        io << "def initialize("
        table.columns.each_with_index do |column, index|
          io << ", " unless index == 0
          io << column.name << " = " << (column.default || "nil")
        end
        io << ")\n"
        table.columns.each do |column|
          io << "  unless " << column.name << ".is_a?(Nil)\n"
          io << "    self." << column.name << " = " << column.name << "\n"
          io << "  end\n"
        end
        io << "end\n\n"
      end

      def generate_columns(io)
        io << "def self.columns\n"
        io << "  {\n"
        table.columns.each do |column|
          io << "    " << column.name << ": " << column.as_crystal << ",\n"
        end
        io << "  }\n"
        io << "end\n\n"
      end

      def generate_attributes_setter(io)
        # TODO: should attributes= have loose type restriction and break at runtime,
        #       or continue to break at compilation?
        io << "def attributes=(attributes : Hash)\n"

        table.columns.each do |column|
          if column.null?
            io << "  if attributes.has_key?(#{ column.name.inspect })\n"
            io << "    #{ column.name } = attributes[#{ column.name.inspect }] as RecordValue\n"
            io << "    if #{ column.name }.is_a?(Nil)\n"
            io << "      self.#{ column.name } = nil\n"
            io << "    else\n"
            io << "      self.#{ column.name } = #{ column.name } as #{ column.to_crystal }\n"
            io << "    end\n"
          else
            io << "  if #{ column.name } = attributes[#{ column.name.inspect }]?\n"
            io << "    self.#{ column.name } = (#{ column.name } as RecordValue) as #{ column.to_crystal }\n"
          end

          if column.default?
            io << "  else\n"
            io << "    self.#{ column.name } = #{ column.default_with_type }\n"
          end

          io << "  end\n\n"
        end
        io << "end\n\n"
      end

      def generate_from_pg_result(io)
        io << "def self.from_pg_result(row : PG::Result::Row)\n"
        io << "  record = new\n"
        io << "  record.new_record = false\n\n"

        io << "  row.each do |attr, value|\n"
        io << "    case attr\n"

        table.columns.each do |column|
          io << "    when #{ column.name.inspect }\n"

          if column.null?
            io << "      record.#{ column.name } = if value.is_a?(Nil)\n"
            io << "        nil\n"
            io << "      else\n"
            io << "        value as #{ column.as_crystal }\n"
            io << "      end\n"
          else
            io << "      record.#{ column.name } = value as #{ column.as_crystal }\n"
          end
        end
        io << "    end\n"
        io << "  end\n\n"

        io << "  record\n"
        io << "end\n\n"
      end

      def generate_properties(io)
        table.columns.each do |column|
          io << "def " << column.name << "\n"
          io << "  @" << column.name << "\n"
          io << "end\n\n"

          # TODO: validate value limit/range
          io << "def " << column.name << "=(value : " << column.to_crystal << ")\n"
          io << "  @" << column.name << " = " << column.to_cast << "\n"
          io << "end\n\n"

          if table.primary_key? && table.primary_key == column.name && table.primary_key != "id"
            io << "def id\n  " << table.primary_key << ";\nend\n\n"
            io << "def id=(value)\n  self." << table.primary_key << " = value\nend\n\n"
          end
        end
      end

      def generate_to_hash(io)
        io << "def to_hash\n"
        io << "  {\n"
        table.columns.each do |column|
          io << "    " << column.name.inspect << " => " << column.name << ",\n"
        end
        io << "  }\n"
        io << "end\n\n"
      end

      def generate_to_tuple(io)
        io << "def to_tuple\n"
        io << "  {"
        table.columns.each_with_index do |column, index|
          io << ", " unless index == 0
          io << column.name
        end
        io << "}\n"
        io << "end\n"
      end

      def to_crystal_s(io : IO)
        io << "@@primary_key = " << (table.primary_key || "id").inspect << "\n"
        io << "@@primary_key_type = " << (table.primary_key_type || "Int32") << "\n"
        io << "@@attribute_names = {" << table.attribute_names.map(&.inspect).join(", ") << "}\n\n"

        generate_initialize(io)
        generate_columns(io)
        generate_from_pg_result(io)
        generate_attributes_setter(io)
        generate_properties(io)
        generate_to_hash(io)
        generate_to_tuple(io)
      end
    end

    Attributes.new(ARGV[0]).to_crystal_s(STDOUT)
  end
end
