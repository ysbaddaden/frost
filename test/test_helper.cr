require "minitest/autorun"
require "../src/frost"

# initialize the mimetype library to avoid lazy loading it on-demand (MT unsafe)
MIME.init(true)

module Frost
  def self.clear_routes
    @@handler = nil
  end
end
