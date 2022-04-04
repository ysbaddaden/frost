module Frost
  UTILS_BIN = "#{__DIR__}/../bin/utils"

  module Utils
    private PLURAL_CACHE = {} of String => String
    private SINGULAR_CACHE = {} of String => String

    macro ecr(template_path, buffer_name = nil)
      {% if buffer_name %}
        {{ `#{UTILS_BIN} ecr #{template_path} #{buffer_name}`.strip }}
      {% else %}
        {{ `#{UTILS_BIN} ecr #{template_path}`.strip }}
      {% end %}
    end

    macro ls(glob)
      {{ `#{UTILS_BIN} ls "#{glob}"`.strip.split("\n") }}
    end

    macro pluralize(word)
      {% word = word.id.stringify %}

      {% if plural = PLURAL_CACHE[word] %}
        {{ plural }}
      {% else %}
        {% plural = `#{UTILS_BIN} pluralize #{word}`.strip.stringify %}
        {% PLURAL_CACHE[word] = plural %}
        {{ plural }}
      {% end %}
    end

    macro singularize(word)
      {% word = word.id.stringify %}

      {% if singular = SINGULAR_CACHE[word] %}
        {{ singular }}
      {% else %}
        {% singular = `#{UTILS_BIN} singularize #{word}`.strip.stringify %}
        {% SINGULAR_CACHE[word] = singular %}
        {{ singular }}
      {% end %}
    end
  end
end
