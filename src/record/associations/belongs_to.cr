#require "../../support/core_ext/string"

module Trail
  class Record
    module Associations
      class BelongsTo
        getter :name
        getter :model_name
        getter :foreign_key

        def initialize(@name)
          @model_name = @name.camelcase
          @foreign_key = "#{ @name }_id"
        end

        # TODO: save association + set foreign key before saving record (if association is unsaved)
        def to_crystal_s(io : IO)
          io << "def #{ name }(reload = false)\n"
          io << "  @#{ name } = nil if reload\n"
          io << "  @#{ name } ||= begin\n"
          io << "    unless #{ foreign_key }.nil?\n"
          io << "      #{ model_name }.find(#{ foreign_key })\n"
          io << "    end\n"
          io << "  end\n"
          io << "end\n\n"

          io << "def #{ name }=(record : #{ model_name })\n"
          io << "  if id = record.id\n"
          io << "    self.#{ foreign_key } = id\n"
          io << "  else\n"
          io << "    @#{ foreign_key } = nil\n"
          io << "  end\n"
          io << "  @#{ name } = record\n"
          io << "end\n\n"

          # FIXME: don't generate if column can't be null
          io << "def #{ name }=(record : Nil)\n"
          io << "  @#{ name } = self.#{ foreign_key } = nil\n"
          io << "end\n\n"

          io << "def build_#{ name }(attributes)\n"
          io << "  self.#{ name } = #{ model_name }.build(attributes)\n"
          io << "end\n\n"

          io << "def create_#{ name }(attributes)\n"
          io << "  self.#{ name } = #{ model_name }.create(attributes)\n"
          io << "end\n"
        end
      end

      BelongsTo.new(ARGV[0]).to_crystal_s(STDOUT)
    end
  end
end
