require "../test_helper"

module Frost
  class Controller
    class ParamsTest < Minitest::Test
      def test_parse_query_string_for_strings
        assert_equal({ "key" => "value" }, Params.parse("key=value"))
        assert_equal({ "key" => "1" }, Params.parse("key=2&key=1"))
        assert_equal({ "a" => "1", "b" => "2" }, Params.parse("a=1&b=2"))
      end

      def test_parse_query_string_for_arrays
        assert_equal({ "a" => ["1", "2"] }, Params.parse("a[]=1&a[]=2"))
        assert_equal({ "a" => ["1"], "b" => ["2"] }, Params.parse("a[]=1&b[]=2"))
        assert_equal({ "key" => ["kept"] }, Params.parse("key=dropped&key[]=kept"))
      end

      def test_parse_query_string_for_hashes
        assert_equal({ "key" => { "name" => "1" } },
                     Params.parse("key[name]=1"))

        assert_equal({ "key" => { "name" => "1", "title" => "value" } },
                     Params.parse("key[name]=1&key[title]=value"))

        assert_equal({ "key" => { "name" => "2" } },
                     Params.parse("key[name]=1&key[name]=2"))
      end

      def test_parse_query_string_for_nested_hashes
        assert_equal({ "key" => { "name" => { "value" => "nested" } } },
                     Params.parse("key[name][value]=nested"))

        assert_equal({ "key" => { "name" => { "value" => { "nested" => "1" } } } },
                     Params.parse("key[name][value][nested]=1"))

        assert_equal({ "key" => { "name" => { "first" => "1", "second" => "2" } } },
                     Params.parse("key[name][first]=1&key[name][second]=2"))

        assert_equal({ "key" => { "name" => { "first" => "1", "first" => "2" } } },
                     Params.parse("key[name][first]=2"))

        assert_equal({ "key" => { "name" => "kept" } },
                     Params.parse("key=dropped&key[name]=kept"))
      end

      def test_parse_query_string_for_nested_hashes_and_arrays
        assert_equal({ "key" => { "name" => ["1", "2"] } },
                     Params.parse("key[name][]=1&key[name][]=2"))

        assert_equal({ "key" => [{ "name" => "1" }, { "name" => "2" }] },
                     Params.parse("key[][name]=1&key[][name]=2"))
      end
    end
  end
end
