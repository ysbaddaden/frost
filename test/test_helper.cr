require "minitest/autorun"
require "../src/trail"

module Trail
  ROOT = "#{ __DIR__ }/.."
  ENVIRONMENT = "test"
  VIEWS_PATH = "#{ __DIR__ }/views"
end

Trail.config.secret_key = SecureRandom.hex(32)

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
