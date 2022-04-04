require "./helpers/*"

abstract struct Frost::View
  module Helpers
    include OutputSafetyHelper
    include TagHelper
    include UrlHelper
  end
end
