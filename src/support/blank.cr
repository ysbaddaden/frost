module Frost
  module Support
    module Blank
      # Always returns false. This method is meant to be overloaded by classes
      # and structs that have a blank state (eg: Nil, Bool or String).
      def blank?
        false
      end

      # Retuns the opposite of `blank?`.
      def present?
        !blank?
      end

      # Returns nil if self is `blank?`, otherwise returns self.
      def presence
        if blank?
          nil
        else
          self
        end
      end
    end
  end
end
