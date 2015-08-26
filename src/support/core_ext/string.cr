require "../blank"
require "../inflector"

module Trail
  module Support
    module CoreExt
      # Port of ActiveSupport String Inflections
      #
      # Copyright (c) 2005-2015 David Heinemeier Hansson
      #
      # * https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/string/inflections.rb
      # * https://github.com/rails/rails/blob/master/activesupport/MIT-LICENSE
      module String
        # Returns true if a string is empty or contains only space, linefeed or tab
        # characters.
        def blank?
          empty? || self =~ /\A\s*\Z/
        end

        # Alias for `camelcase`.
        def camelize
          camelcase
        end

        # Replaces underscores with dashes.
        def dasherize
          gsub('_', '-')
        end

        # Demodulizes and underscores string then appends `_id` to generate the
        # foreign key column name of an association.
        #
        # ```
        # "Message".foreign_key  # => "message_id"
        # "Admin::Post".foreign_key  # => "post_id"
        # ```
        def foreign_key
          "#{ demodulize.underscore }_id"
        end

        # Removes the module part from a constant name.
        #
        # ```
        # "Admin::Post".demodulize  # => "Post"
        # "Trail::Support::Inflector".demodulize  # => "Inflector"
        # ```
        def demodulize
          if idx = rindex("::")
            self[(idx + 2) .. -1]
          else
            self
          end
        end

        # Capitalizes the string, replaces underscores for spaces and drops any
        # leading `_id`.
        #
        # ```
        # "published_at".humanize  # => "Published at"
        # "author_id".humanize  # => "Author"
        # ```
        def humanize
          capitalize
            .chomp("_id")
            .gsub('_', ' ')
        end

        # Removes special chars from a string so it may be used in a pretty URL.
        #
        # ```
        # " Mon pauvre zébu ankylosé. ".parameterize  # => "mon-pauvre-zebu-ankylose"
        # ```
        def parameterize
          transliterate
            .downcase
            .gsub(/[^\w\d_-]+/, '-')
            .gsub(/-{2,}/, '-')
            .gsub(/(^-|-$)/, "")
        end

        # Pluralizes the last word of a string.
        #
        # See `Trail::Support::Inflector.pluralize`
        def pluralize
          Trail::Support::Inflector.pluralize(self)
        end

        # Singularizes the last word of a string.
        #
        # See `Trail::Support::Inflector.singularize`
        def singularize
          Trail::Support::Inflector.singularize(self)
        end

        # Underscores a string then pluralizes the last word.
        #
        # ```
        # "Post".tableize         # => "posts"
        # "PostComment".tableize  # => "post_comments"
        # ```
        def tableize
          underscore.pluralize
        end

        # Capitalizes all words and replaces some characters to generate nice titles.
        #
        # ```
        # "Mon pauvre zébu ankylosé".titleize  # => "Mon Pauvre Zébu Ankylosé"
        # ```
        def titlecase
          underscore
            .humanize
            .gsub(/\s\b[\w]/) { |char| char.upcase }
        end

        # Alias for `titlecase`.
        def titleize
          titlecase
        end

        # Replaces any accented characters for their non accented counterparts.
        def transliterate
          gsub(Trail::Support::Inflector::TRANSLITERATE_MAPPING)
        end
      end
    end
  end
end

# :nodoc:
class String
  include Trail::Support::Blank
  include Trail::Support::CoreExt::String
end
