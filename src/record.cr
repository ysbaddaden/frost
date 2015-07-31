require "./record/errors"
require "./record/connection"
require "./record/finders"
require "./record/persistence"

module Trail
  class Record
    def self.table_name
      @@table_name ||= name.tableize
    end

    def self.primary_key
      @@primary_key
    end

    # :nodoc:
    def self.primary_key_type
      @@primary_key_type
    end

    def self.attribute_names
      @@attribute_names
    end

    def self.build(attributes : Hash)
      new.tap do |record|
        record.attributes = attributes
      end
    end

    #def to_hash
    #  Hash.zip(self.class.attribute_names.to_a, to_tuple.to_a)
    #end

    abstract def to_tuple

    macro generate_attributes
      {{ run "./record/attributes.cr", @type.name.stringify }}
    end

    macro inherited
      generate_attributes
    end
  end
end
