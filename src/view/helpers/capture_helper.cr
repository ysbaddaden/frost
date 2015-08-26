module Trail
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
