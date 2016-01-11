require "json"

module Frost
  abstract class Record
    module Serialization
      def serializable_hash
        Hash.zip(self.class.attribute_names.to_a, to_tuple.to_a)
      end

      def to_json
        serializable_hash.to_json
      end

      def to_json(io)
        serializable_hash.to_json(io)
      end
    end
  end
end
