module Trail
  module Config
    macro attribute(name, type)
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
end
