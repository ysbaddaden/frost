abstract struct Frost::View
  module Helpers::OutputSafetyHelper
    def with_output_buffer : SafeString
      original = @__str__

      begin
        SafeString.build do |__str__|
          yield @__str__ = SafeBuffer.new(__str__)
        end
      ensure
        @__str__ = original
      end
    end

    def concat(obj : String)
      __str__ << html_escape(obj)
    end

    def concat(obj)
      __str__ << obj
    end

    def raw(obj : String) : SafeString
      obj.html_safe
    end

    def raw(obj : SafeString) : SafeString
      obj
    end

    def raw(obj)
      obj
    end

    def html_safe?(obj) : Bool
      SafeBuffer.html_safe?(obj)
    end

    def html_escape(obj)
      SafeBuffer.html_escape(obj)
    end
  end
end
