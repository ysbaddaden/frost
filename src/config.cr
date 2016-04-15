module Frost
  module Config
    macro attribute(name, type)
      @@{{ name.id }} : {{ type.id }}?

      def self.{{ name.id }}
        @@{{ name.id }} as {{ type.id }}
      end

      def self.{{ name.id }}=(value)
        @@{{ name.id }} = value
      end
    end

    attribute :secret_key, String
  end

  def self.config
    Config
  end

  def self.root
    @@root as String
  end

  def self.root=(path : String)
    @@root = path
  end

  def self.environment
    @@environment as String
  end

  def self.environment=(environment : String)
    @@environment = environment
  end
end
