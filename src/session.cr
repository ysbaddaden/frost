class Frost::Session
  def self.generate_sid
    Random::Secure.hex(16)
  end

  getter id : String
  getter updated_at : Time

  def initialize(
    @id : String = self.class.generate_sid,
    @data : Hash(String, String) = {} of String => String,
  )
    @updated_at = Time.utc
  end

  def []=(key : String, value : String) : String
    @data[key] = value
  end

  def [](key : String) : String
    @data[key]
  end

  def []?(key : String) : String?
    @data[key]?
  end

  def delete(key : String) : String?
    @data.delete(key)
  end

  def clear : Nil
    @data.clear
  end

  def touch! : Nil
    @updated_at = Time.utc
  end

  def reset! : Nil
    @id = Frost::Session.generate_sid
    @data.clear
  end
end
