module Frost
  class View
    module CaptureHelper
      # Captures the string returns by yielding the block or anything written to
      # a new output buffer.
      #
      # This method is required to allow the block form of helpers like
      # `TagHelper#content_tag` within ECR templates:
      #
      # ```ecr
      # <%= content_tag :div, { "class" => "user-details" } do %>
      #   name: <%= user.name %>
      # <% end %>
      #
      # # <div class="user-details">
      # #   name: Julien
      # # </div>
      # ```
      def capture(&block)
        value = nil
        buffer = with_output_buffer { value = yield }

        if buffer.empty?
          if value.is_a?(String)
            return value
          end
        end

        buffer
      end

      # Appends the string to the current buffer. This happens automatically in
      # ECR templates, but may be necessary in pure-crystal helpers to capture
      # more than the last returned string in a `#capture` block. The following
      # example example returns `"foobar"` but would only return `"bar"` without
      # the calls to concat:
      #
      # ```
      # capture do
      #   concat "foo"
      #   concat "bar"
      # end
      # ```
      def concat(html)
        __buf__ << html
      end

      protected def __buf__
        output_buffers.last
      end

      protected def with_output_buffer
        String.build do |__str__|
          output_buffers << __str__

          begin
            yield
          ensure
            output_buffers.pop
          end
        end
      end

      private def output_buffers
        @output_buffers ||= [] of String::Builder
      end
    end
  end
end
