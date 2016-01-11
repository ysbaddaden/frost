struct HTTP::Headers
  def self.from(other)
    headers = new

    if other
      other.each { |key, value| headers[key] = value.to_s }
    end

    headers
  end

  def self.from(other : HTTP::Headers)
    other.dup
  end
end
