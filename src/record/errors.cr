module Frost
  abstract class Record
    class Error < Exception
    end

    class ConnectionError < Exception
    end

    #class RangeError < Error
    #end

    class RecordNotFound < Error
    end

    class RecordInvalid < Error
      getter record : Record

      def initialize(@record)
        errors = record.errors.full_messages.join(", ")
        super "Invalid #{ record.class.name }: #{ errors }"
      end
    end

    class RecordNotSaved < Error
      getter record : Record

      def initialize(@record)
        super "Failed to save #{ record.class.name }"
      end
    end

    class RecordNotDestroyed < Error
      getter record : Record

      def initialize(@record)
        super "Failed to destroy #{ record.class.name }"
      end
    end

    class MigrationError < Error
    end

    class DeleteRestrictionError < Error
    end
  end
end
