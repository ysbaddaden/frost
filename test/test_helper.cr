require "minitest/autorun"
require "../src/frost"

module Frost
  def self.clear_routes
    @@handler = nil
  end
end
