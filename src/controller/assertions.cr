require "xml"

module Frost
  class Controller
    module Assertions
      def after_teardown
        @__xml_parsed_response_body = nil
        __assert_select_cache.clear
        super
      end

      def assert_response(status_code, message = nil)
        assert_equal status_code, response.status_code, message
      end

      def assert_redirected_to(url, message = nil)
        assert_includes [301, 302, 303], response.status_code
        assert_equal url, response.headers["Location"], message
      end

      def assert_select(selector, count = nil, text = nil)
        unless nodes = __assert_select_cache[selector]?
          xml = @__xml_parsed_response_body || parse_xml_response_body
          xpath = css_to_xpath(selector)
          nodes = __assert_select_cache[selector] = xml.xpath_nodes(xpath)
        end

        if text
          assert nodes.any?, "Expected #{ selector.inspect } to match at least 1 node, but nothing was found."

          if text.is_a?(Regex)
            assert nodes.any? { |node| text =~ node.text },
              "Expected text for #{ selector.inspect } to match #{ text.inspect } but got #{ nodes.map(&.text).join }"
          else
            assert nodes.any? { |node| text == node.text },
              "Expected text for #{ selector.inspect } to be #{ text.inspect } but got #{ nodes.map(&.text).join }"
          end
        else
          if count
            assert_equal count, nodes.size,
              "Expected #{ selector.inspect } to match exactly #{ count } node(s) but got #{ nodes.size }"
          else
            assert nodes.size > 0,
              "Expected #{ selector.inspect } to match at least 1 node, but found nothing"
          end
        end
      end

      def refute_select(selector, text = nil)
        unless nodes = __assert_select_cache[selector]?
          xml = @__xml_parsed_response_body || parse_xml_response_body
          xpath = css_to_xpath(selector)
          nodes = __assert_select_cache[selector] = xml.xpath_nodes(xpath)
        end

        if text
          if text.is_a?(Regex)
            refute nodes.any? { |node| text =~ node.text },
              "Expected text for #{ selector.inspect } to not match #{ text.inspect } but got #{ nodes.map(&.text).join }"
          else
            refute nodes.any? { |node| text == node.text },
              "Expected text for #{ selector.inspect } to not be #{ text.inspect } but got #{ nodes.map(&.text).join }"
          end
        end
      end

      private def __assert_select_cache
        @__assert_select_cache ||= {} of String => XML::NodeSet
      end

      # Reference: https://en.wikibooks.org/wiki/XPath/CSS_Equivalents
      # TODO: E ~ F => //E/following-sibling::*[count(F)]
      protected def css_to_xpath(selector)
        segments = selector.split(/\s*(\s|>|\+)\s*/)

        "//" + segments.map do |segment|
          case segment
          when /\s/ then "//"
          when ">"  then "/"
          when "+"  then "/following-sibling::*[1]/self::"
          else
            constraints = segment.split(/(\.[^.#[:]+|#[^.#[:]+|:[^.#[:]+|\[[^\]]+])/).reject(&.empty?)
            constraints.unshift("*") if constraints.first =~ /^\.|#|:|\[/
            constraints.map { |c| css_constraint_to_xpath(c) }.join
          end
        end.join
      end

      # TODO: :not(attr) => [ not(attr) ]
      protected def css_constraint_to_xpath(constraint)
        case constraint
        when /^\.(.+)$/
          "[ contains(concat(\" \", @class, \" \"), concat(\" \", #{ $1.inspect }, \" \")) ]"

        when /^#(.+)$/
          "[ @id = #{ $1.inspect } ]"

        when /^\[(.+?)([~\|\*!\^\$]?)=['"](.+)['"]\]$/
          css_attribute_to_xpath($1, $2, $3)

        when /^\[(.+)\]$/
          "[ @#{ $1 } ]"

        when ":first-child"
          "/descendant::*[1]"

        when ":last-child"
          "[ last() ]"

        when /^:nth-child\((odd|even|\d+)\)$/
          case $1
          when "odd"  then "[ (position() mod 2) = 1 ]"
          when "even" then "[ (position() mod 2) = 0 ]"
          else             "[ (position() mod #{ $1 }) = 1 ]"
          end

        when /^:/
          raise ArgumentError.new("Unsupported pseudo selector #{ constraint }")

        else
          constraint
        end
      end

      protected def css_attribute_to_xpath(attr, operator, value)
        case operator
        when "~"
          "[ contains(concat(\" \", @#{ attr }, \" \"), concat(\" \", #{ value.inspect }, \" \") ]"
        when "|"
          "[ @#{ attr } = #{ value.inspect } or starts-with(@#{ attr }, concat(#{ value.inspect }, \"-\")) ]"
        when "*"
          "[ contains(@#{ attr }, #{ value.inspect }) ]"
        when "^"
          "[ starts-with(@#{ attr }, #{ value.inspect }) ]"
        when "$"
          "[ substring(@#{ attr }, string-length(@#{ attr }) - 2) = #{ value.inspect } ]"
        when "!"
          "[ @#{ attr } != #{ value.inspect } ]"
        else
          "[ @#{ attr } = #{ value.inspect } ]"
        end
      end

      # TODO: consider moving as HTTP::Response.xml
      protected def parse_xml_response_body
        content_type = response.headers["Content-Type"]

        if content_type.to_s !~ /^(text\/html|text\/xml)\b/
          raise ArgumentError.new("Expected response to be text/html or text/xml but was #{ content_type }")
        end

        # FIXME: to_s is required to avoid a segfault
        XML.parse_html(response.body.to_s)
      end
    end
  end
end
