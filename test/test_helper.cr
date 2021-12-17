require "minitest/autorun"
require "../src/frost"

module Frost::Router
  def self.clear
    @@handler = nil
  end
end
