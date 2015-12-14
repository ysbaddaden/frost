require "../blank"

module Frost
  module Support
    module CoreExt
      module Nil
        # Nil is always blank.
        def blank?
          true
        end

        #def to_i16
        #  0_i16
        #end

        #def to_i32
        #  0_i32
        #end

        #def to_i64
        #  0_i64
        #end

        #def to_f32
        #  0_f32
        #end

        #def to_f64
        #  0_f64
        #end
      end
    end
  end
end

# :nodoc:
struct Nil
  include Frost::Support::Blank
  include Frost::Support::CoreExt::Nil
end
