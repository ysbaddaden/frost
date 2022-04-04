abstract struct Frost::View
  module Helpers::UrlHelper
    def link_to(name, url : String | SafeString, **attributes) : SafeString
      link_to(url, **attributes) do
        concat name if name
      end
    end

    def link_to(url : String | SafeString, **attributes) : SafeString
      attributes = attributes.merge(href: url)
      content_tag(:a, **attributes) { yield }
    end
  end
end
