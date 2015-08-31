require "../../support/core_ext/string"

module Trail
  class Record
    module Associations
      class HasMany
        getter :name, :relation
        getter :singular
        getter :model_name
        getter :foreign_key

        def initialize(@name, @relation)
          @singular = @name.singularize
          @model_name = singular.camelcase
          @foreign_key = "#{ relation }_id"
        end

        # TODO: Collection object for .build, .create, .delete, <<
        def to_crystal_s(io : IO)
          # TODO: generate an INNER JOIN query
          io << "def #{ name }\n"
          io << "  @#{ name } ||= #{ model_name }.where({ #{ foreign_key }: id })\n"
          io << "end\n\n"

          # TODO: deassociate current records (applying dependent customization)
          io << "def #{ name }=(records)\n"
          io << "  records.each do |record|\n"
          io << "    record.#{ relation } = self\n"
          io << "    record.save\n"
          io << "  end\n"
          io << "  @#{ name } = records\n"
          io << "end\n\n"

          # TODO: cast array elements to column type (eg: String?, Int32, ...)
          io << "def #{ singular }_ids\n"
          io << "  #{ name }.pluck(#{ model_name }.primary_key)\n"
          io << "end\n\n"

          io << "def #{ singular }_ids=(ids)\n"
          io << "  self.#{ name } = #{ model_name }.find(ids)\n"
          io << "end\n\n"
        end
      end

      HasMany.new(ARGV[0], ARGV[1]).to_crystal_s(STDOUT)
    end
  end
end
