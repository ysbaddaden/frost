module Frost
  module Support
    # Port of ActiveSupport::Inflector
    #
    # Copyright (c) 2005-2015 David Heinemeier Hansson
    #
    # * https://github.com/rails/rails/blob/master/activesupport/lib/active_support/inflector/inflections.rb
    # * https://github.com/rails/rails/blob/master/activesupport/lib/active_support/inflector/transliterate.rb
    # * https://github.com/rails/rails/blob/master/activesupport/MIT-LICENSE
    module Inflector
      # :nodoc:
      TRANSLITERATE_MAPPING = {
        'À' => 'A', 'Á' => 'A', 'Â' => 'A', 'Ã' => 'A', 'Ä' => 'A', 'Å' => 'A', 'Æ' => "AE",
        'Ç' => 'C',
        'È' => 'E', 'É' => 'E', 'Ê' => 'E', 'Ë' => 'E',
        'Ì' => 'I', 'Í' => 'I', 'Î' => 'I', 'Ï' => 'I',
        'Ð' => 'D',
        'Ñ' => 'N',
        'Ò' => 'O', 'Ó' => 'O', 'Ô' => 'O', 'Õ' => 'O', 'Ö' => 'O', 'Ő' => 'O', 'Ø' => 'O',
        'Ù' => 'U', 'Ú' => 'U', 'Û' => 'U', 'Ü' => 'U', 'Ű' => 'U',
        'Ý' => 'Y', 'Þ' => "TH", 'ß' => "ss", 'Œ' => "OE",
        'à' => 'a', 'á' =>'a', 'â' => 'a', 'ã' => 'a', 'ä' => 'a', 'å' => 'a', 'æ' => "ae",
        'ç' => 'c',
        'è' => 'e', 'é' => 'e', 'ê' => 'e', 'ë' => 'e',
        'ì' => 'i', 'í' => 'i', 'î' => 'i', 'ï' => 'i',
        'ð' => 'd',
        'ñ' => 'n',
        'ò' => 'o', 'ó' => 'o', 'ô' => 'o', 'õ' => 'o', 'ö' => 'o', 'ő' => 'o', 'ø' => 'o',
        'ù' => 'u', 'ú' => 'u', 'û' => 'u', 'ü' => 'u', 'ű' => 'u',
        'ý' => 'y', 'þ' => "th", 'ÿ' => 'y', 'œ' => "oe"
      }

      # :nodoc:
      record Rule, re : Regex, block : (String -> String)?, replacement : String?

      # :nodoc:
      PLURAL_RULES = [] of Rule

      # :nodoc:
      SINGULAR_RULES = [] of Rule

      # :nodoc:
      UNCOUNTABLE_RULES = [] of Regex

      # Declares a pluralization rule, using a block.
      #
      # The block will receive the singular word and is expected to return the
      # pluralized version.
      macro plural(re, &block)
        PLURAL_RULES.unshift(Rule.new({{ re }}, ->({{ block.args.argify }} : String) { {{ block.body }} }, nil))
      end

      # Declares a pluralization rule.
      #
      # ```
      # plural /sis\Z/i, "ses"
      # plural /(alias|status)\Z/i, "\1es"
      # ```
      #
      # Note that the `\1` and `\2` backreferences will be replaced.
      macro plural(re, replacement)
        PLURAL_RULES.unshift(Rule.new({{ re }}, nil, {{ replacement }}))
      end

      # Declares a singularization rule, using a block.
      #
      # The block will receive the plural word and is expected to return the
      # singularized version.
      macro singular(re, &block)
        SINGULAR_RULES.unshift(Rule.new({{ re }}, ->({{ block.args.argify }} : String) { {{ block.body }} }, nil))
      end

      # Declares a singularization rule.
      #
      # ```
      # singular /ses\Z/i, "sis"
      # singular /(\Aanaly)ses\Z/i, "\1sis"
      # ```
      #
      # Note that the `\1` and `\2` backreferences will be replaced.
      macro singular(re, replacement)
        SINGULAR_RULES.unshift(Rule.new({{ re }}, nil, {{ replacement }}))
      end

      # Declares an irregular word pluralization.
      #
      # ```
      # irregular "person", "people"
      # ```
      macro irregular(singular, plural)
        plural(Regex.new(Regex.escape({{ singular }}) + "\\Z", Regex::Options::IGNORE_CASE)) do |word|
          word =~ /\A[A-ZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎIÐÑÒÓÔÕÖŐØÙÚÛÜŰÝÞŒ]/ ? {{ plural }}.capitalize : {{ plural }}
        end

        singular(Regex.new(Regex.escape({{ plural }}) + "\\Z", Regex::Options::IGNORE_CASE)) do |word|
          word =~ /\A[A-ZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎIÐÑÒÓÔÕÖŐØÙÚÛÜŰÝÞŒ]/ ? {{ singular }}.capitalize : {{ singular }}
        end
      end

      # Declares an uncountable word.
      #
      # ```
      # uncountable "wiki"
      # ```
      macro uncountable(words)
        {% for word in words %}
          UNCOUNTABLE_RULES << Regex.new(Regex.escape({{ word }}) + "\\Z", Regex::Options::IGNORE_CASE)
        {% end %}
      end

      # Returns true if the last word of a string is countable.
      def self.countable?(word)
        UNCOUNTABLE_RULES.none? { |rule| word =~ rule }
      end

      # Pluralizes the last word of a string.
      #
      # ```
      # "account".pluralize     # => "accounts"
      # "the person".pluralize  # => "the people"
      # ```
      def self.pluralize(str)
        apply_rules(str, PLURAL_RULES)
      end

      # Singularizes the last word of a string.
      #
      # ```
      # "accounts".singularize    # => "account"
      # "the people".singularize  # => "the person"
      # ```
      def self.singularize(str)
        apply_rules(str, SINGULAR_RULES)
      end

      private def self.apply_rules(word, rules)
        if word.strip != "" && countable?(word)
          rules.each do |rule|
            if m = rule.re.match(word)
              if block = rule.block
                return word.gsub(rule.re, &block)
              elsif replacement = rule.replacement
                return word.gsub(rule.re, replacement.gsub("\1", $1?.to_s).gsub("\2", $2?.to_s))
              end
            end
          end
        end

        word
      end

      plural /\Z/, "s"
      plural /s\Z/i, "s"
      plural /(ax|test)is\Z/i, "\1es"
      plural /(octop|vir)us\Z/i, "\1i"
      plural /(alias|status)\Z/i, "\1es"
      plural /(bu)s\Z/i, "\1ses"
      plural /(buffal|tomat)o\Z/i, "\1oes"
      plural /([ti])um\Z/i, "\1a"
      plural /sis\Z/i, "ses"
      plural /(?:([^f])fe|([lr])f)\Z/i, "\1\2ves"
      plural /(hive)\Z/i, "\1s"
      plural /([^aeiouy]|qu)y\Z/i, "\1ies"
      plural /(x|ch|ss|sh)\Z/i, "\1es"
      plural /(matr|vert|ind)(?:ix|ex)\Z/i, "\1ices"
      plural /([m|l])ouse\Z/i, "\1ice"
      plural /\A(ox)\Z/i, "\1en"
      plural /(quiz)\Z/i, "\1zes"

      singular /s\Z/i, ""
      singular /(n)ews\Z/i, "\1ews"
      singular /([ti])a\Z/i, "\1um"
      singular /((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses\Z/i, "\1\2sis"
      singular /(\Aanaly)ses\Z/i, "\1sis"
      singular /([^f])ves\Z/i, "\1fe"
      singular /(hive)s\Z/i, "\1"
      singular /(tive)s\Z/i, "\1"
      singular /([lr])ves\Z/i, "\1f"
      singular /([^Aaeiouy]|qu)ies\Z/i, "\1y"
      singular /(s)eries\Z/i, "\1eries"
      singular /(m)ovies\Z/i, "\1ovie"
      singular /(x|ch|ss|sh)es\Z/i, "\1"
      singular /([m|l])ice\Z/i, "\1ouse"
      singular /(bus)es\Z/i, "\1"
      singular /(o)es\Z/i, "\1"
      singular /(shoe)s\Z/i, "\1"
      singular /(cris|ax|test)es\Z/i, "\1is"
      singular /(octop|vir)i\Z/i, "\1us"
      singular /(alias|status)es\Z/i, "\1"
      singular /\A(ox)en/i, "\1"
      singular /(vert|ind)ices\Z/i, "\1ex"
      singular /(matr)ices\Z/i, "\1ix"
      singular /(quiz)zes\Z/i, "\1"
      singular /(database)s\Z/i, "\1"

      irregular "person", "people"
      irregular "man", "men"
      irregular "child", "children"
      irregular "sex", "sexes"
      irregular "move", "moves"
      irregular "cow", "kine"

      uncountable %w(equipment information rice money species series fish sheep jeans)
    end
  end
end
