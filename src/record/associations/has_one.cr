require "../../support/core_ext/string"

module Trail
  class Record
    module Associations
      class HasOne
        getter :name
        getter :model_name
        getter :foreign_key

        def initialize(@name)
          @model_name = @name.camelcase
          @foreign_key = "#{ @name }_id"
        end

        def to_crystal_s(io : IO)
          io << "def #{ name }\n"
          io << "  #{ model_name }.where({ #{ foreign_key }: id }).first\n"
          io << "end\n\n"

          io << "def #{ name }=(record : Trail::Record)\n"
          io << "  record.#{ foreign_key } = id\n"
          io << "  record.save\n"
          io << "end\n\n"

          io << "def build_#{ name }(attributes)\n"
          io << "  #{ model_name }.build(attributes)\n"
          io << "end\n\n"

          io << "def create_#{ name }(attributes)\n"
          io << "  record = #{ model_name }.build(attributes)\n"
          io << "  record.#{ foreign_key } = id\n"
          io << "  record.save\n"
          io << "  record\n"
          io << "end\n"
        end
      end

      HasOne.new(ARGV[0]).to_crystal_s(STDOUT)
    end
  end
end
