require "minitest/autorun"
require "../src/trail"

module Trail
  ROOT = "#{ __DIR__ }/.."
  ENVIRONMENT = "test"
  VIEWS_PATH = "#{ __DIR__ }/views"
end

class ApplicationView < Trail::View
end

class LayoutsView < ApplicationView
end
