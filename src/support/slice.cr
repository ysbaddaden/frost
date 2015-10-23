struct Slice(T)
  def self.from_hexstring(string)
    Slice(UInt8).new(string.size >> 1) do |i|
      string[i << 1, 2].to_u8(16)
    end
  end
end

