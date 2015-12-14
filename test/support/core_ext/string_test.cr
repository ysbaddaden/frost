require "../../test_helper"
require "../../../src/support/core_ext/string"

module Frost::Support
  class StringTest < Minitest::Test
    def test_foreign_key
      assert_equal "message_id", "Message".foreign_key
      assert_equal "post_id", "Admin::Post".foreign_key
    end

    def test_demodulize
      assert_equal "Message", "Message".demodulize
      assert_equal "Post", "Admin::Post".demodulize
      assert_equal "Inflector", "Frost:Support::Inflector".demodulize
    end

    def test_dasherize
      assert_equal "Hello world!",  "Hello world!".dasherize
      assert_equal "Hello-world!",  "Hello_world!".dasherize
      assert_equal "hello-World!",  "hello_World!".dasherize
    end

    def test_humanize
      assert_equal "Employee salary", "employee_salary".humanize
      assert_equal "Employee", "employee_id".humanize
      assert_equal "Underground", "underground".humanize
    end

    def test_parameterize
      assert_equal "hello-world", "Hello World!".parameterize
      assert_equal "mon-pauvre-zebu-ankylose-choque-deux-fois-ton-wagon-jaune",
                   " Mon pauvre zébu ankylosé - choque deux fois ton wagon jaune. ".parameterize
    end

    def test_pluralize
      assert_equal "", "".pluralize
      assert_equal "posts", "post".pluralize
      assert_equal "bases", "basis".pluralize
    end

    def test_singularize
      assert_equal "", "".singularize
      assert_equal "post", "posts".singularize
      assert_equal "basis", "bases".singularize
    end

    def tableize
      assert_equal "accounts", "Account".tableize
      assert_equal "primary_spokesmen", "PrimarySpokesman".tableize
      assert_equal "node_children", "NodeChild".tableize
    end

    def test_titleize
      assert_equal "Active Record", "ActiveRecord".titleize
      assert_equal "Active Record", "active_record".titleize
      assert_equal "Action Web Service", "action web service".titleize
      assert_equal "Action Web Service", "Action Web Service".titleize
      assert_equal "Action Web Service", "Action web service".titleize
      assert_equal "Actionwebservice", "actionwebservice".titleize
      assert_equal "Actionwebservice", "Actionwebservice".titleize
      assert_equal "David's Code", "david's code".titleize
      assert_equal "David's Code", "David's code".titleize
      assert_equal "David's Code", "david's Code".titleize
    end

    def test_transliterate
      assert_equal "AEroskobing", "Ærøskøbing".transliterate

      assert_equal "Voix ambigue d'un coeur qui, au zephir, prefere les jattes de kiwis.",
                   "Voix ambiguë d'un cœur qui, au zéphir, préfère les jattes de kiwis.".transliterate

      assert_equal "Mon pauvre zebu ankylose choque deux fois ton wagon jaune.",
                   "Mon pauvre zébu ankylosé choque deux fois ton wagon jaune.".transliterate
    end
  end
end
