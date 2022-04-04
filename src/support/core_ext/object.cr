require "../safe_buffer"

class Object
  def to_s(buffer : Frost::SafeBuffer) : Nil
    to_s(buffer.@io)
  end
end
