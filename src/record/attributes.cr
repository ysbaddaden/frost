require "../support/core_ext/string"
require "./connection"

module Trail
  class Record

    # TODO: generate json_mapping
    class Attributes
      getter :class_name, :table

      def initialize(@class_name)
        @table = Record.connection.table(@class_name.tableize)
      end

      def generate_initialize(str)
        str << "def initialize("
        table.columns.each_with_index do |column, index|
          str << ", " unless index == 0
          str << "@" << column.name << " = " << (column.default || "nil")

          if types = column.type.to_crystal
            str << " : " << types
            str << " | ::Nil" unless types.includes?("::Nil") || types.index("?")
          end
        end
        str << ")\n"
        str << "end\n\n"
      end

      def generate_attributes_setter(str)
        str << "def attributes=(attributes : Hash)\n"
        table.columns.each do |column|
          str << "  if attributes.has_key?(#{ column.name.inspect })\n"

          if column.null?
            str << "    if attributes[#{ column.name.inspect }] == nil\n"
            str << "      self.#{ column.name } = nil\n"
            str << "    else\n"
            str << "      self.#{ column.name } = attributes[#{ column.name.inspect }] as #{ column.type.as_crystal }\n"
            str << "    end\n"
          else
            str << "    self.#{ column.name } = attributes[#{ column.name.inspect }] as #{ column.type.as_crystal }\n"
          end

          if column.default?
            str << "  else\n"
            str << "    self.#{ column.name } = #{ column.default_with_type }\n"
          end

          str << "  end\n\n"
        end
        str << "end\n\n"
      end

      def generate_properties(str)
        table.columns.each do |column|
          str << "def " << column.name << "\n"
          str << "  @" << column.name << "\n"
          str << "end\n\n"

          # TODO: validate value limit/range
          str << "def " << column.name << "=(value : " << column.to_crystal << ")\n"
          #str << "def " << column.name << "=(value)\n"
          str << "  @" << column.name << " = " << column.to_cast << "\n"
          str << "end\n\n"

          if table.primary_key? && table.primary_key == column.name && table.primary_key != "id"
            str << "alias_method :id, :" << table.primary_key << "\n\n"
            str << "def id=(value)\n  self." << table.primary_key << " = value\nend\n\n"
          end
        end
      end

      def generate_to_hash(str)
        str << "def to_hash\n"
        str << "  {\n"
        table.columns.each do |column|
          str << "    " << column.name.inspect << " => " << column.name << ",\n"
        end
        str << "  }\n"
        str << "end\n\n"
      end

      def generate_to_tuple(str)
        str << "def to_tuple\n"
        str << "  {"
        table.columns.each_with_index do |column, index|
          str << ", " unless index == 0
          str << column.name
        end
        str << "}\n"
        str << "end\n"
      end

      def to_crystal_s
        String.build do |str|
          str << "@@primary_key = " << (table.primary_key || "id").inspect << "\n"
          str << "@@primary_key_type = " << (table.primary_key_type || "Int32") << "\n"
          str << "@@attribute_names = {" << table.attribute_names.map(&.inspect).join(", ") << "}\n\n"

          generate_initialize(str)
          generate_attributes_setter(str)
          generate_properties(str)
          generate_to_hash(str)
          generate_to_tuple(str)
        end
      end
    end

    at_exit do
      attributes = Attributes.new(ARGV[0])
      puts attributes.to_crystal_s
    end
  end
end
