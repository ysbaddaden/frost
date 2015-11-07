require "./record/errors"
require "./record/connection"
require "./record/callbacks"
require "./record/finders"
require "./record/associations"
require "./record/persistence"
require "./record/validation"
require "./support/core_ext/time"


module Trail
  # TODO: associations (has_many :children, belongs_to :parent)
  # TODO: dirty attributes
  class Record
    extend Finders
    include Callbacks
    include Associations
    include Persistence
    include Validation

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
      record = new
      record.attributes = attributes
      record
    end

    def ==(other)
      false
    end

    def ==(other : Record)
      self.class == other.class && id == other.id
    end

    #def to_hash
    #  Hash.zip(self.class.attribute_names.to_a, to_tuple.to_a)
    #end

    def to_param
      id.to_s
    end

    abstract def to_tuple

    # OPTIMIZE: avoid loading attributes twice
    #
    # it doesn't work with the following:
    # % unless @type.methods.any? { |m| m.name.stringify == "attributes=" } %
    macro generate_attributes
      {{ run "./record/attributes.cr", @type.name.stringify }}
    end

    macro inherited
      generate_attributes
    end
  end
end
