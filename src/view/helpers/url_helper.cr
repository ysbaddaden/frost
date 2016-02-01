module Frost
  abstract class View
    module UrlHelper
      # Formats an anchor HTML tag.
      # ```
      # link_to "main page", "/"
      # # => <a href="/">main page</a>
      #
      # link_to "Crystal", "http://crystal-lang.org/", { class: "external" }
      # # => <a href="http://crystal-lang.org" class="external">Crystal</a>
      # ```
      def link_to(title, url, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:href] = url.to_s
        content_tag(:a, title, attrs)
      end

      # Formats an anchor HTML tag.
      #
      # ```ecr
      # <%= link_to user_profile_path(user.id), { class: "lnk" } do %>
      #   <%= user.name %>'s profile
      # <% end %>
      #
      # # <a href="/profile/1" class="lnk">
      # #   Julien's profile
      # # </a>
      # ```
      def link_to(url, attributes = nil)
        link_to(capture { yield }, url, attributes)
      end

      # Formats an anchor HTML tag if +test+ if true, otherwise prints the
      # anchor title only.
      def link_to_if(test, title, url, attributes = nil)
        if test
          link_to(title, url, attributes)
        else
          title
        end
      end

      def link_to_if(test, url, attributes = nil)
        if test
          link_to(url, attributes) { yield }
        else
          yield
        end
      end

      # Formats an anchor HTML tag unless +test+ if true, otherwise prints the
      # anchor title only.
      def link_to_unless(test, title, url, attributes = nil)
        if test
          title
        else
          link_to(title, url, attributes)
        end
      end

      def link_to_unless(test, url, attributes = nil)
        if test
          yield
        else
          link_to(url, attributes) { yield }
        end
      end

      # Formats a single button HTML form.
      # ```
      # button_to "remove", tag_path("name"), method: "delete", attributes: { "class" => "btn-danger" }
      #
      # # <form action="/tags/name" method="post">
      # #   <input type="hidden" name="_method" value="delete"/>
      # #   <button class="btn-danger">remove</button>
      # # </form>
      # ```
      def button_to(title, url, method = "post", attributes = nil)
        form_tag url, method, attributes: { class: "button_to" } do
          button_tag title, attributes
        end
      end

      # Formats a single button HTML form.
      #
      # ```ecr
      # <%= button_to poke_user_path(user.id), method: "post" do %>
      #   Poke <%= user.name %>
      # <% end %>
      #
      # # <form action="/users/1/poke" method="post">
      # #   <input type="hidden" name="_method" value="delete"/>
      # #   <button class="btn-danger">Poke Julien</button>
      # # </form>
      # ```
      def button_to(url, method = "post", attributes = nil)
        button_to(capture { yield }, url, method, attributes)
      end
    end
  end
end
