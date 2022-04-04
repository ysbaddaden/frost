require "./core_ext/string"

struct Frost::SafeString
  def self.build
    new String.build { |str| yield str }
  end

  def self.new(obj : self)
    obj
  end

  def initialize(@string : String)
  end

  def html_safe : self
    self
  end

  def html_safe? : Bool
    true
  end

  def to_s(io : IO) : Nil
    io.write @string.to_slice
  end

  def to_s : String
    @string
  end

  def ==(other : String)
    @string == other
  end

  def ==(other : SafeString)
    @string == other.to_s
  end

  def ==(other)
    false
  end
end
