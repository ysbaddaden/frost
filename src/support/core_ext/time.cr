#module Trail
#  module Support
#    module CoreExt
#      module Time
#        def to_i16
#          to_i.to_i16
#        end
#
#        def to_i32
#          to_i.to_i32
#        end
#
#        def to_i64
#          to_i.to_i64
#        end
#
#        def to_f32
#          to_f.to_f32
#        end
#
#        def to_f64
#          to_f.to_f64
#        end
#      end
#    end
#  end
#end

## :nodoc:
#struct Time
#  include Trail::Support::CoreExt::Time
#end
