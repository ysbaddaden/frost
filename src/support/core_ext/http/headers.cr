struct HTTP::Headers
  def self.from(other)
    headers = new

    if other
      headers.merge!(other)
    end

    headers
  end

  def self.from(other : HTTP::Headers)
    other.dup
  end
end
