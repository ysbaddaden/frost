require "./test_helper"
require "../src/query/builder"

module Frost
  class Record
    class Query::BuilderTest < Minitest::Test
      def test_select
        empty = Query::Builder.new("pages", adapter)
        find = empty.select(:id)
        select = find.select(:chapter_id, :title)

        assert_query "SELECT * FROM `pages`", empty
        assert_query "SELECT `pages`.`id` FROM `pages`", find
        assert_query "SELECT `pages`.`id`, `pages`.`chapter_id`, `pages`.`title` FROM `pages`", select
      end

      def test_join
        pages = Query::Builder.new("pages", adapter).join("INNER JOIN chapters ON pages.chapter_id = chapters.id")
        stories = pages.join("INNER JOIN stories ON chapters.story_id = stories.id")

        assert_query "SELECT * FROM `pages` INNER JOIN chapters ON pages.chapter_id = chapters.id", pages
        assert_query "SELECT * FROM `pages` INNER JOIN chapters ON pages.chapter_id = chapters.id INNER JOIN stories ON chapters.story_id = stories.id", stories
      end

      def test_where
        pages = Query::Builder.new("pages", adapter).where("1 = 1")
        chapter_pages = pages.where("chapter_id = 3")

        assert_query "SELECT * FROM `pages` WHERE (1 = 1)", pages
        assert_query "SELECT * FROM `pages` WHERE (1 = 1) AND (chapter_id = 3)", chapter_pages
      end

      def test_where_with_params
        time = Time.now
        pages = Query::Builder.new("pages", adapter).where("chapter_id = ?", 3)

        assert_query "SELECT * FROM `pages` WHERE (chapter_id = 3)", pages

        assert_query "SELECT * FROM `pages` WHERE (chapter_id = 3) AND (published = 't' AND published_at < '#{ time }')",
          pages.where("published = ? AND published_at < ?", true, time)

        assert_query "SELECT * FROM `pages` WHERE (chapter_id = 3) AND (data ? '1'::json)",
          pages.where("data \\? ?::json", "1")
      end

      def test_where_with_hash
        assert_query "SELECT * FROM `pages` WHERE (`pages`.`chapter_id` = 3 AND `pages`.`published` = 't')",
          Query::Builder.new("pages", adapter).where({ chapter_id: 3, published: true })
      end

      def test_where_with_nested_hash
        assert_query "SELECT * FROM `pages` WHERE (`pages`.`chapter_id` = 3 AND `chapters`.`published` = 't')",
          Query::Builder.new("pages", adapter).where({ chapter_id: 3, chapters: { published: true } })
      end

      def test_where_in
        pages = Query::Builder.new("pages", adapter)
        chapters = Query::Builder.new("chapters", adapter)

        assert_query "SELECT * FROM `pages` WHERE (`pages`.`chapter_id` IN (1, 2, 3))",
          pages.where({ chapter_id: [1, 2, 3] })

        assert_query "SELECT * FROM `pages` WHERE (`pages`.`chapter_id` IN ('1', 2, 'f'))",
          pages.where({ chapter_id: ["1", 2, false] })

        assert_query "SELECT * FROM `chapters` WHERE (book_id NOT IN ('4', '5', '6'))",
          chapters.where("book_id NOT IN (?)", %w(4 5 6))
      end

      def test_group
        pages = Query::Builder.new("pages", adapter).group(:chapter_id)
        published = pages.group(:published)

        assert_query "SELECT * FROM `pages` GROUP BY `pages`.`chapter_id`", pages
        assert_query "SELECT * FROM `pages` GROUP BY `pages`.`chapter_id`, `pages`.`published`", published
      end

      def test_having
        time = Time.now
        pages = Query::Builder.new("pages", adapter).group(:chapter_id)
        published = pages.having({ published: true })

        assert_query "SELECT * FROM `pages` GROUP BY `pages`.`chapter_id`", pages
        assert_query "SELECT * FROM `pages` GROUP BY `pages`.`chapter_id` HAVING (`pages`.`published` = 't')", published
        assert_query "SELECT * FROM `pages` GROUP BY `pages`.`chapter_id` HAVING (`pages`.`published` = 't') AND (published_at > '#{ time }')",
          published.having("published_at > ?", time)
      end

      def test_order
        pages = Query::Builder.new("pages", adapter)

        assert_query "SELECT * FROM `pages` ORDER BY `pages`.`id` ASC",
          pages.order(:id)

        assert_query "SELECT * FROM `pages` ORDER BY `pages`.`title` DESC",
          pages.order({ title: :desc })

        assert_query "SELECT * FROM `pages` ORDER BY `pages`.`title` ASC, `pages`.`created_at` DESC",
          pages.order({ title: :asc, created_at: :desc })

        assert_query "SELECT * FROM `pages` ORDER BY `pages`.`title` ASC, `pages`.`created_at` DESC",
          pages.order(:title).order(:created_at, :desc)

        #assert_query "SELECT * FROM `pages` ORDER BY id ASC, title DESC",
        #  pages.order("id ASC, title DESC")
      end

      def test_reorder
        pages = Query::Builder.new("pages", adapter)

        assert_query "SELECT * FROM `pages` ORDER BY `pages`.`chapter_id` ASC",
          pages.order(:id).reorder(:chapter_id)

        assert_query "SELECT * FROM `pages` ORDER BY `pages`.`created_at` DESC",
          pages.order(:created_at).reorder({ created_at: :desc })
      end

      def test_limit
        pages = Query::Builder.new("pages", adapter)
        assert_query "SELECT * FROM `pages` LIMIT 10", pages.limit(10)
        assert_query "SELECT * FROM `pages` LIMIT 5 OFFSET 25", pages.limit(5, 25)
        assert_query "SELECT * FROM `pages` LIMIT 1", pages.limit(5, 25).limit(1)
      end

      def assert_query(sql, query)
        result = query.to_sql

        if result.is_a?(String)
          assert_equal sql.strip, result.strip
        else
          assert_equal sql.strip, result[0].strip
        end
      end

      class MockAdapter
        def escape(value)
          case value
          when Int, Float
            value.to_s
          when Bool
            value ? "'t'" : "'f'"
          else
            "'#{ value.to_s.gsub("'", "\\'") }'"
          end
        end

        def quote(column_name)
          "`#{ column_name.to_s }`"
        end
      end

      private def adapter
        MockAdapter.new
      end
    end
  end
end
