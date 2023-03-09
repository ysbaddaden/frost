# Parses CSS selectors and attempts to tranform them into XML Path Language
# (XPath) 1.0. This is required to use CSS selectors against `XML` documents
# that rely on `libxml2`.
#
# The generated XPath have only been tested against `libxml2` v2.9.10 as
# packaged on Ubuntu 20.04.
#
# References:
#
# - [Selectors Level 4](https://www.w3.org/TR/selectors-4/)
# - [CSS Syntax Module Level 3](https://www.w3.org/TR/css-syntax-3/)
# - [XML Path Language (XPath) 1.0](https://www.w3.org/TR/1999/REC-xpath-19991116/)
#
# Existing implementations (they may differ):
#
# - <https://en.wikibooks.org/wiki/XPath/CSS_Equivalents>
# - <https://github.com/sparklemotion/nokogiri/blob/main/lib/nokogiri/css/xpath_visitor.rb>
# - <https://css2xpath.github.io/>
struct Frost::CSS::Selectors
  class SyntaxError < Exception
  end

  def self.to_xpath(selector : String) : String
    reader = Char::Reader.new(selector)
    new(reader).to_xpath
  end

  @combinator : Char?
  @tag_name_pos : Int32?

  def initialize(@reader : Char::Reader)
  end

  def to_xpath : String
    # lstrip
    while @reader.current_char.whitespace?
      @reader.next_char
    end
    return "" unless next?

    String.build do |xpath|
      xpath << '/' << '/'
      to_xpath(xpath, end_char: '\0', reference: '*')
    end
  end

  # TODO: namespaces `ns|E` (?)
  protected def to_xpath(xpath : IO, end_char : Char, reference : Char | String) : Int32
    @tag_name = false # has either type or universal selector
    first = true
    char = @reader.current_char

    loop do
      # p [char, {first: first, tag_name: @tag_name}]

      case char
      when end_char, '\0'      # stop parsing (nested) or end-of-string ('\0')
        break

      when .whitespace?        # descendant combinator (maybe)
        skip_whitespace
        @tag_name = false
        next if first
        @combinator = ' '

      when '>', '+', '~'       # combinator
        @combinator = char
        @tag_name = false
        skip_whitespace

      when '.', '#', '[', ':'  # compound selector
        with_combinator(xpath) do
          xpath << reference unless @tag_name
          case char
          when '.' then parse_class_selector(xpath)
          when '#' then parse_id_selector(xpath)
          when '[' then parse_attribute_selector(xpath)
          when ':' then parse_pseudo_selector(xpath)
          end
          @tag_name = true
        end

      when ','
        raise "ERROR: selector lists aren't implemented"

      when '*'                 # universal selector (*)
        with_combinator(xpath) do
          xpath << '*'
        end
        @tag_name = true

      else                     # type selector (tag name)
        with_combinator(xpath) do
          parse_type_selector(xpath)
        end
        @tag_name = true
      end

      first = false
      char = @reader.next_char
    end

    @reader.pos - 1
  end

  private def parse_type_selector(xpath, at pos = nil) : Nil
    if pos
      original_pos = @reader.pos
      @reader.pos = pos
    else
      @tag_name_pos = @reader.pos
    end

    xpath << @reader.current_char
    parse_ident(xpath)

    if original_pos
      @reader.pos = original_pos
    end
  end

  private def with_combinator(xpath) : Nil
    case @combinator
    when ' ' then xpath << '/' << '/'
    when '>' then xpath << '/'
    when '+' then xpath << "/following-sibling::*[1]/self::"
    when '~' then xpath << "/following-sibling::"
    end

    yield

    @combinator = nil
  end

  private def parse_class_selector(xpath) : Nil
    xpath << %{[contains(concat(" ", normalize-space(@class), " "), concat(" ", "}
    parse_ident(xpath)
    xpath << %{", " "))]}
  end

  private def parse_id_selector(xpath) : Nil
    xpath << %{[@id="}
    parse_ident(xpath)
    xpath << %{"]}
  end

  private def parse_attribute_selector(xpath) : Nil
    attr_pos = @reader.pos
    operator = lookahead_attribute_operator
    value_pos = @reader.pos

    xpath << '['

    case operator
    when ']'
      xpath << '@'
      parse_ident(xpath, at: attr_pos)
      @reader.pos = value_pos
    when '='
      xpath << '@'
      parse_ident(xpath, at: attr_pos)
      xpath << '='
      parse_attr_value(xpath, at: value_pos)
      # TODO: [foo="bar" i] (case insensitive)
    when '*'
      xpath << "contains(@"
      parse_ident(xpath, at: attr_pos)
      xpath << ',' << ' '
      parse_attr_value(xpath, at: value_pos)
      xpath << ')'
    when '^'
      xpath << "starts-with(@"
      parse_ident(xpath, at: attr_pos)
      xpath << ',' << ' '
      parse_attr_value(xpath, at: value_pos)
      xpath << ')'
    when '|'
      xpath << '@'
      parse_ident(xpath, at: attr_pos)
      xpath << '='
      parse_attr_value(xpath, at: value_pos)
      xpath << " or starts-with(@"
      parse_ident(xpath, at: attr_pos)
      xpath << ", concat("
      parse_attr_value(xpath, at: value_pos)
      xpath << %{, "-"))}
    when '$'
      xpath << "substring(@"
      parse_ident(xpath, at: attr_pos)
      xpath << ", string-length(@"
      parse_ident(xpath, at: attr_pos)
      xpath << ") - (string-length("
      parse_attr_value(xpath, at: value_pos)
      xpath << ") - 1)) = "
      parse_attr_value(xpath, at: value_pos)
    when '~'
      xpath << %{contains(concat(" ", normalize-space(@}
      parse_ident(xpath, at: attr_pos)
      xpath << %{), " "), concat(" ", }
      parse_attr_value(xpath, at: value_pos)
      xpath << %{, " "))}
    when '!'
      xpath << '@'
      parse_ident(xpath, at: attr_pos)
      xpath << '!' << '='
      parse_attr_value(xpath, at: value_pos)
    end

    xpath << ']'
  end

  private def lookahead_attribute_operator : Char
    loop do
      case char = @reader.next_char
      when ']'
        return ']'
      when '='
        return '='
        break
      when '*', '^', '|', '$', '~', '!'
        expect_next_char '='
        return char
      when '\0'
        raise SyntaxError.new("expected ']', '*', '^', '|', '$', '~' or '!' but reached end-of-string")
      end
    end
  end

  private def parse_attr_value(xpath, at pos) : Nil
    @reader.pos = pos
    xpath << '"'

    case char = @reader.next_char
    when '"', '\''
      parse_string(xpath, char)
    else
      @reader.previous_char
      parse_ident(xpath)
    end
    expect_next_char ']'

    xpath << '"'
  end

  private def parse_string(xpath, end_char) : Nil
    escaped = false

    loop do
      case @reader.peek_next_char
      when end_char
        unless escaped
          @reader.next_char # => end_char
          return
        end
      when '\\'
        escaped = true
        @reader.next_char # => '\\'
        next
      when '\0'
        raise SyntaxError.new("expected '#{end_char}' but reached end-of-string")
      end

      xpath << @reader.next_char
      escaped = false
    end
  end

  # TODO: :nth-col() (?)
  # TODO: :nth-last-col() (?)
  private def parse_pseudo_selector(xpath) : Nil
    if parse_ident?("empty")
      xpath << "[count(*)=0]"

    elsif parse_ident?("checked")
      xpath << %{[(name()="input" or name()="option") and (@checked or @selected)]}

    elsif parse_ident?("disabled")
      xpath << %{[(name()="input" or name()="select" or name()="option" or name()="textarea" or name()="button") and @disabled]}

    elsif parse_ident?("enabled")
      xpath << %{[(name()="input" or name()="select" or name()="option" or name()="textarea" or name()="button") and not(@disabled)]}

    elsif parse_ident?("required")
      xpath << %{[(name()="input" or name()="select" or name()="textarea") and @required]}

    elsif parse_ident?("optional")
      xpath << %{[(name()="input" or name()="select" or name()="textarea") and not(@required)]}

    elsif parse_ident?("not")
      parse_function(xpath) do
        xpath << "[not("
        @reader.next_char # skip '('
        selectors = Selectors.new(@reader)
        @reader.pos = selectors.to_xpath(xpath, end_char: ')', reference: "self::node()")
        xpath << ")]"
      end

    elsif parse_ident?("has")
      parse_function(xpath) do
        xpath << '['
        @reader.next_char # skip '('
        selectors = Selectors.new(@reader)
        @reader.pos = selectors.to_xpath(xpath, end_char: ')', reference: '*')
        xpath << ']'
      end

    elsif parse_ident?("first-child")
      xpath << "[not(preceding-sibling::*)]"

    elsif parse_ident?("last-child")
      xpath << "[not(following-sibling::*)]"

    elsif parse_ident?("only-child")
      xpath << "[not(preceding-sibling::*) and not(following-sibling::*)]"

    elsif parse_ident?("nth-child")
      parse_function(xpath) { parse_nth_child(xpath) }

    elsif parse_ident?("nth-last-child")
      parse_function(xpath) { parse_nth_last_child(xpath) }

    elsif parse_ident?("first-of-type")
      raise "ERROR: unsupported *:only-of-type" unless pos = @tag_name_pos
      xpath << "[1]"

    elsif parse_ident?("last-of-type")
      raise "ERROR: unsupported *:only-of-type" unless pos = @tag_name_pos
      xpath << "[last()]"

    elsif parse_ident?("only-of-type")
      raise "ERROR: unsupported *:only-of-type" unless pos = @tag_name_pos
      xpath << "[not(preceding-sibling::"
      parse_type_selector(xpath, at: pos)
      xpath << ") and not(following-sibling::"
      parse_type_selector(xpath, at: pos)
      xpath << ")]"

    elsif parse_ident?("nth-of-type")
      parse_function(xpath) { parse_nth_of_type(xpath) }

    elsif parse_ident?("nth-last-of-type")
      parse_function(xpath) { parse_nth_last_of_type(xpath) }

    else
      raise "ERROR: unsupported pseudo selector at character #{@reader.pos} of #{@reader.string}"
    end
  end

  private def parse_function(xpath, &) : Nil
    expect_next_char '('
    # skip_whitespace
    yield
    # skip_whitespace
    expect_next_char ')'
  end

  private def parse_nth_child(xpath) : Nil
    parse_nth(xpath, "(count(preceding-sibling::*) + 1)")
  end

  private def parse_nth_last_child(xpath) : Nil
    parse_nth(xpath, "(count(following-sibling::*) + 1)")
  end

  private def parse_nth_of_type(xpath) : Nil
    parse_nth(xpath, "position()")
  end

  private def parse_nth_last_of_type(xpath) : Nil
    parse_nth(xpath, "(last() - position() + 1)")
  end

  private def parse_nth(xpath, counter) : Nil
    if parse_ident?("odd")
      xpath << '[' << counter << " mod 2 = 1]"
    elsif parse_ident?("even")
      xpath << '[' << counter << " mod 2 = 0]"
    else
      a, n, op, b = parse_nth_value
      if n
        case op
        when nil, '+'
          cmp = a < 0 ? "<= ": ">="
          index = b || 0
          modulo = b ? (b % a.abs) : 0
          xpath << '[' << counter << ' ' << cmp << ' ' << index << " and " << counter << " mod " << a.abs << '=' << modulo << ']'
        when '-'
          modulo = a < 0 ? -1 : (a - b) % a
          xpath << '[' << counter << " mod " << a << '=' << modulo << ']'
        end
      else
        xpath << '[' << counter << '=' << a << ']'
      end
    end
  end

  #private def parse_nth_of_type(xpath) : Nil
  #  if parse_ident?("odd")
  #    xpath << "[position() mod 2 = 1]"
  #  elsif parse_ident?("even")
  #    xpath << "[position() mod 2 = 0]"
  #  else
  #    a, n, op, b = parse_nth_value
  #    if n
  #      case op
  #      when nil, '+'
  #        cmp = a < 0 ? "<=" : ">="
  #        c = b || 0
  #        d = b ? (b % a).abs : 0
  #        xpath << "[position() " << cmp << " " << c << " and position() mod " << a.abs << " = " << d << ']'
  #      when '-'
  #        raise "ERROR: unsupported :nth-child(-An-B)" if a < 0
  #        xpath << "[position() mod " << a << " = " << ((a - b) % a) << ']'
  #      end
  #    else
  #      xpath << "[position() = " << a << ']'
  #    end
  #  end
  #end

  # private def parse_nth_of_type(xpath) : Nil
  #   if parse_ident?("odd")
  #     xpath << "[(position() mod 2) = 1]"
  #   elsif parse_ident?("even")
  #     xpath << "[(position() mod 2) = 0]"
  #   else
  #     a, n, op, b = parse_nth_value
  #     if n
  #       case op
  #       when nil
  #         if a > 0 # An
  #           xpath << "[(position() mod " << a << ") = 0]"
  #         else     # -An
  #           xpath << "[(position() <= 0) and (position() mod " << a << ") = 0]"
  #         end
  #       when '+'
  #         if a > 0 # An+B
  #           xpath << "[(position() >= " << b << ") and (position() mod " << a << ") = " << (b % a) << ']'
  #         else     # -An+B
  #           xpath << "[(position() <= " << b << ") and (position() mod " << a.abs << ") = " << (b % a).abs << ']'
  #         end
  #       when '-'
  #         if a > 0 # An-B
  #           xpath << "[(position() mod " << a << ") = " << ((a - b) % a) << ']'
  #         else     # -An-B
  #           raise "ERROR: unsupported :nth-child(-An-B)"
  #         end
  #       else
  #         raise "unreachable"
  #       end
  #     else
  #       xpath << "[position() = " << a << ']'
  #     end
  #   end
  # end

  private def parse_nth_value : {Int32, Char?, Char?, Int32}
    a = parse_integer
    n = nil
    op = nil
    b = 0_i32

    if @reader.peek_next_char == 'n'
      n = @reader.next_char
    end

    # skip_whitespace

    case @reader.peek_next_char
    when '-', '+'
      op = @reader.next_char
      # skip_whitespace
      b = parse_integer
    end

    return {a, n, op, b}
  end

  # Zero malloc variant of Int32.new(String)
  private def parse_integer : Int32
    value = 0_i32
    negative = false

    case @reader.peek_next_char
    when '-'
      negative = true
      @reader.next_char
    when '+'
      @reader.next_char
    end

    expect @reader.peek_next_char, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'

    loop do
      case @reader.peek_next_char
      when '0'..'9'
        value *= 10
        value &+= @reader.next_char.to_i32
      else
        break
      end
    end

    negative ? value * -1 : value
  end

  private def parse_ident?(ident) : Bool
    pos = @reader.pos
    if ident.each_char { |char| break true unless char == @reader.next_char }
      @reader.pos = pos
      false
    else
      true
    end
  end

  private def parse_ident(xpath, at pos = nil) : Nil
    @reader.pos = pos if pos

    loop do
      case @reader.peek_next_char
      when .alphanumeric?, '-', '_'
        xpath << @reader.next_char
      else
        break
      end
    end
  end

  private def expect_next_char(*chars)
    expect(@reader.next_char, *chars)
  end

  private def expect(char, *chars)
    unless chars.includes?(char)
      raise SyntaxError.new("Expected '#{chars.join("', '")}' but got '#{char}' at character #{@reader.pos} of #{@reader.string.inspect}")
    end
  end

  private def skip_whitespace : Nil
    while @reader.peek_next_char.whitespace?
      @reader.next_char
    end
  end

  private def next? : Bool
    @reader.current_char != '\0'
  end

  private def lstrip_whitespace : Nil
    while @reader.current_char.whitespace?
      @reader.next_char
    end
  end
end
