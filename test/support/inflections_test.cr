require "../test_helper"
require "../../src/support/inflections"

module Frost
  class InflectionsTest < Minitest::Test
    SINGULAR_TO_PLURAL = {
      "search"      => "searches",
      "switch"      => "switches",
      "fix"         => "fixes",
      "box"         => "boxes",
      "process"     => "processes",
      "address"     => "addresses",
      "case"        => "cases",
      "stack"       => "stacks",
      "wish"        => "wishes",
      "fish"        => "fish",
      "jeans"       => "jeans",
      "funky jeans" => "funky jeans",

      "category"    => "categories",
      "query"       => "queries",
      "ability"     => "abilities",
      "agency"      => "agencies",
      "movie"       => "movies",

      "archive"     => "archives",

      "index"       => "indices",

      "wife"        => "wives",
      "safe"        => "saves",
      "half"        => "halves",

      "move"        => "moves",

      "person"      => "people",
      "salesperson" => "salespeople",

      "spokesman"   => "spokesmen",
      "man"         => "men",
      "woman"       => "women",

      "basis"       => "bases",
      "diagnosis"   => "diagnoses",
      "diagnosis_a" => "diagnosis_as",

      "datum"       => "data",
      "medium"      => "media",
      "analysis"    => "analyses",

      "node_child"  => "node_children",
      "child"       => "children",

      "experience"  => "experiences",
      "day"         => "days",

      "comment"     => "comments",
      "foobar"      => "foobars",
      "newsletter"  => "newsletters",

      "old_news"    => "old_news",
      "news"        => "news",

      "series"      => "series",
      "species"     => "species",

      "quiz"        => "quizzes",

      "perspective" => "perspectives",

      "ox"          => "oxen",
      "photo"       => "photos",
      "buffalo"     => "buffaloes",
      "tomato"      => "tomatoes",
      "dwarf"       => "dwarves",
      "elf"         => "elves",
      "information" => "information",
      "equipment"   => "equipment",
      "bus"         => "buses",
      "status"      => "statuses",
      "status_code" => "status_codes",
      "mouse"       => "mice",

      "louse"       => "lice",
      "house"       => "houses",
      "octopus"     => "octopi",
      "virus"       => "viri",
      "alias"       => "aliases",
      "portfolio"   => "portfolios",

      "vertex"      => "vertices",
      "matrix"      => "matrices",
      "matrix_fu"   => "matrix_fus",

      "axis"        => "axes",
      "testis"      => "testes",
      "crisis"      => "crises",

      "rice"        => "rice",
      "shoe"        => "shoes",

      "horse"       => "horses",
      "prize"       => "prizes",
      "edge"        => "edges",

      "cow"         => "kine",
      "database"    => "databases"
    }

    def test_pluralize
      SINGULAR_TO_PLURAL.each do |singular, plural|
        assert_equal plural, Inflections.pluralize(singular)
        assert_equal plural.capitalize, Inflections.pluralize(singular.capitalize)
      end
    end

    def test_singularize
      SINGULAR_TO_PLURAL.each do |singular, plural|
        assert_equal singular, Inflections.singularize(plural)
        assert_equal singular.capitalize, Inflections.singularize(plural.capitalize)
      end
    end
  end
end

