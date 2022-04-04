require "./core_ext/object"
require "./safe_string"

struct Frost::SafeBuffer
  def initialize(@io : IO)
  end

  # ECR uses `<<` for writing raw strings.
  def <<(obj : String) : self
    @io.write obj.to_slice
    self
  end

  def <<(obj : Nil) : self
    self
  end

  def <<(obj) : self
    obj.to_s(@io)
    self
  end

  def write_unsafe(obj : String) : Nil
    SafeBuffer.html_escape(@io, obj)
  end

  def write_unsafe(obj) : Nil
    @io << obj
  end

  def puts : Nil
    @io.puts
  end

  def raw : IO
    @io
  end

  def self.html_safe?(obj : SafeString) : Bool
    obj.html_safe?
  end

  def self.html_safe?(obj) : Bool
    obj.to_s.each_char do |char|
      return false if {'&', '<', '>', '"', '\''}.includes?(char)
    end
    true
  end

  def self.html_escape(obj : SafeString) : SafeString
    obj
  end

  def self.html_escape(obj) : SafeString
    str = obj.to_s
    str = str.gsub { |char| html_escape(char) } unless html_safe?(str)
    str.html_safe
  end

  def self.html_escape(io : IO, obj) : Nil
    obj = obj.to_s

    # if html_safe?(obj)
    #   io << obj.html_safe
    # else
      obj.each_char do |char|
        io << html_escape(char)
      end
    # end
  end

  # :nodoc:
  def self.html_escape(char : Char) : Char | String
    case char
    when '&' then "&amp;"
    when '<' then "&lt;"
    when '>' then "&gt;"
    when '"' then "&quot;"
    when '\'' then "&#27;"
    else char
    end
  end
end
