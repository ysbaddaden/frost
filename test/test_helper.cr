require "minitest/autorun"
require "../src/trail"

module Trail
  VIEWS_PATH = "#{ __DIR__ }/views"

  self.root = File.expand_path("..", __DIR__)
  self.environment = ENV.fetch("TRAIL_ENV", "test")

  module Config
    self.secret_key = SecureRandom.hex(32)
  end
end

abstract class ApplicationView < Trail::View
end

class LayoutsView < ApplicationView
  def initialize(@controller)
  end
end

module Minitest::Assertions
  def assert_equal_unordered(expected : Array, got : Array)
    assert_equal expected.size, got.size

    grouped = expected.group_by { |value| value }

    expected.group_by { |value| value }
      .each { |key, values| assert_equal values, grouped[key]? }
  end
end
