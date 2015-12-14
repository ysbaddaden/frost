module Frost
  class Record
    # Record Validations
    #
    # The `#valid?` method will invoke the `#validate` method, which does
    # nothing by default, but may be overloaded in your models to validate it by
    # adding error messages to `#errors`. The `#valid?` method may be invoked
    # manually, to test the validity of a record, but it will also always be
    # invoked when saving a record.
    #
    # Example:
    # ```
    # class Post < Frost::Record
    #   def validate
    #     if title.blank?
    #       errors.add(:title, "Title is required")
    #     elsif title.size > 500
    #       errors.add(:title, "Title must be 100 characters maximum")
    #     end
    #
    #     if body.blank?
    #       errors.add(:body, "Body is required")
    #     end
    #   end
    # end
    #
    # post = Post.new(title: "")
    # post.save # => false
    # post.errors.any? # => true
    # post.errors.each { |attr_name, messages| }
    # post.errors.full_messages # => ["title is required", "body is required"]
    # ```
    module Validation
      class Errors < Hash(Symbol, Array(String))
        # :nodoc:
        def initialize(@record : Record)
          super()
        end

        # Adds an error message for an attribute.
        #
        # ```
        # post.errors.add(:title, "title is required")
        # ```
        def add(attr_name : Symbol, message : String)
          if message.is_a?(Symbol)
            message = message.to_s
          end
          self[attr_name] ||= [] of String
          self[attr_name] << message
        end

        # Returns a flattened list of error messages of all attributes.
        #
        # ```
        # post.errors.add(:title, "title is required")
        # post.errors.add(:body, "body is required")
        # post.errors.full_messages # => ["title is required", "body is required"]
        # ```
        def full_messages
          values.flatten
        end

        def to_json
          full_messages.to_json
        end
      end

      # Overload to implement validations. Does nothing by default.
      def validate
      end

      # Runs validations for this record then returns true if there are no errors,
      # and false otherwise.
      def valid?
        errors.clear
        validate
        errors.empty?
      end

      # The error messages associated to this record. See `Errors`.
      def errors
        @errors ||= Errors.new(self)
      end
    end
  end
end
