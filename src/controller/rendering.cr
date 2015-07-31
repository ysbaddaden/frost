require "../view"
require "../support/mime"

module Trail
  class Controller
    # TODO: render template
    module Rendering
      # Sets the HTTP status code and skips rendering.
      #
      # You are advised to prefer a 204 No Content, which means that there
      # aren't any body, over a 200 OK which would imply that there is a body to
      # parse.
      #
      # Raises DoubleRenderError if the controller already rendered or redirected.
      def head(status)
        prevent_double_rendering do
          response.status_code = status.to_i
        end
      end

      # Redirects to a given URI.
      #
      # ```
      # redirect_to post_url(@post.id)
      # ```
      #
      # The default HTTP status is 303 See Other, which tells the client to
      # follow the redirect with a GET method, whereas a 302 Found would
      # instruct to reuse the same HTTP method (eg: PATCH). See
      # https://en.wikipedia.org/wiki/HTTP_302 for more details.
      #
      # You may want to overload the default status:
      # ```
      # redirect_to posts_url, status: 301
      # redirect_to posts_url, status: 307
      # ```
      #
      # Raises DoubleRenderError if the controller already rendered or redirected.
      def redirect_to(uri, status = 303)
        prevent_double_rendering do
          response.status_code = status.to_i
          response.headers["Location"] = uri.to_s
        end
      end

      # Renders the response body.
      #
      # Sets the HTTP status code, the `Content-Type` header (based on format)
      # and eventually calls `render_to_string`.
      #
      # You may render the template for the current controller action, which
      # will search for a `controller_name/action_name.format.ecr` template (for
      # instance `posts/index.html.ecr`):
      # ```
      # render
      # ```
      #
      # You may render the template for a specific action, which will search for
      # a `controller_name/show.format.ecr` template (for instance
      # `posts/show.html.ecr`):
      # ```
      # render :show
      # ```
      #
      # You may specify a specific format (searches for a `posts/show.json.ecr`
      # template):
      # ```
      # render :show, format: "json"
      # ```
      #
      # You may instead render a text directly:
      # ```
      # render text: "I'm done"
      # ```
      #
      # Raises DoubleRenderError if the controller already rendered or redirected.
      def render(action = nil, text = nil, format = nil, status = 200)
        format ||= self.format

        prevent_double_rendering do
          response.status_code = status.to_i
          response.headers["Content-Type"] = Support::Mime.mime_type(format)
          response.body = render_to_string(action, text, format)
        end
      end

      # Renders a template. Unlike `render` this won't set the response body.
      #
      # You may render the template for a specific action, which will search for
      # a `controller_name/show.format.ecr` template (for instance
      # `posts/show.html.ecr`):
      # ```
      # render_to_string :show
      # ```
      #
      # You may specify a specific format (searches for a `posts/show.json.ecr`)
      # templates:
      # ```
      # render_to_string :show, format: "json"
      # ```
      #
      # You may instead render a text directly:
      # ```
      # render_to_string text: "I'm done"
      # ```
      def render_to_string(action = nil, text = nil, format = nil)
        if text
          text.to_s
        else
          view.render(action || action_name, format: format)
        end
      end

      # Returns the requested format as a String.
      #
      # Examples:
      #
      # * `"json"` for a `/posts.json` request
      # * `"html"` for a `/posts.html` request
      # * `"html"` for a `/posts` request
      #
      # TODO: parse request's Accept header
      def format
        @format ||= begin
                      if format = params["format"]?
                        if format.is_a?(String)
                          format
                        end
                      end

                      "html"
                    end
      end

      # Returns true if the controller already rendered.
      def already_rendered?
        !!@__rendered
      end

      protected def prevent_double_rendering
        raise DoubleRenderError.new if already_rendered?
        yield
        @__rendered = true
      end

      #macro def view : Trail::View+
      #  @view ||= {{ @type.name.gsub(/Controller\Z/, "View") }}.new(self)
      #end

      # :nodoc:
      macro generate_view_class
        {% name = @type.name.gsub(/Controller\Z/, "View") %}

        {% unless name.stringify == "ApplicationView" %}
          class ::{{ name.id }} < ApplicationView
          end

          protected def view
            @view ||= {{ name.id }}.new(self)
          end
        {% end %}
      end
    end
  end
end
