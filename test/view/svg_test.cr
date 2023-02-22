require "./test_helpers"

describe "Frost::SVG" do
  include Frost::View::TestHelpers

  describe "content_type" do
    struct Example < Frost::SVG
      def template
      end
    end

    it "returns the SVG mimetype" do
      assert_equal "image/svg+xml; charset=utf-8", Example.new.content_type
    end
  end

  describe "element" do
    struct Example < Frost::SVG
      def template
        svg xmlns: "http://www.w3.org/2000/svg", width: 24, height: 24, viewBox: "0 0 24 24" do
          path d: "M0 0h24v24H0z", fill: "none"
          path d: "M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zm4.24 16L12 15.45 7.77 18l1.12-4.81-3.73-3.23 4.92-.42L12 5l1.92 4.53 4.92.42-3.73 3.23L16.23 18z"
        end
      end
    end

    it "renders" do
      svg =
        %(<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">) +
          %(<path d="M0 0h24v24H0z" fill="none"/>) +
          %(<path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zm4.24 16L12 15.45 7.77 18l1.12-4.81-3.73-3.23 4.92-.42L12 5l1.92 4.53 4.92.42-3.73 3.23L16.23 18z"/>) +
        %(</svg>)
      assert_equal svg, render Example.new
    end
  end
end
