require "../safe_string"
require "../safe_buffer"

class String
  # Transforms a String into a SafeString.
  def html_safe : Frost::SafeString
    Frost::SafeString.new(self)
  end

  # A String is _never_ safe.
  def html_safe? : Bool
    false
  end

  # ECR transforms `<%= "" %>` into `"".to_s(buffer)` that must always be
  # escaped (possibly untrusted output).
  def to_s(buffer : Frost::SafeBuffer) : Nil
    buffer.write_unsafe(self)
  end

  def ==(other : Frost::SafeString)
    self == other.to_s
  end
end
