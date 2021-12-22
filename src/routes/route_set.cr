require "uri"

module Frost::Routes
  alias Params = Hash(String, String?)

  struct Match(T)
    getter payload : T
    getter params : Params

    def initialize(@payload : T, @params : Params)
    end
  end

  struct Route(T)
    getter payload : T
    getter path : String
    getter regex : Regex

    # nodoc
    TRANSFORMS = {
      /\(/ => "(?:",                             # OPTIONAL: LEFT PAREN
      /\)/ => ")?",                              # OPTIONAL: RIGHT PAREN
      /\./ => "\\.",                             # CHARACTER: DOT
      /\*([\p{L}\p{N}_]+)/ => "(?<\\1>.*?)",     # NAMED GLOB PARAM
      #/\*/ => "(?:.*?)",                         # UNAMED GLOB
      /:([\p{L}\p{N}_]+)/ => "(?<\\1>[^\\/]+?)", # NAMED PARAM
    }

    def initialize(@path : String, @payload : T)
      @regex = to_regex(path)
    end

    private def to_regex(path) : Regex
      expression = TRANSFORMS.reduce(path) { |s, (re, replace)| s.gsub(re, replace) }
      Regex.new("^#{expression}$")
    end

    def matches?(path) : Params?
      if data = @regex.match(path)
        decode(data.named_captures)
      end
    end

    private def decode(params : Params) : Params
      params.each do |key, value|
        next unless value
        params[key] = URI.decode(value) if value.includes?('%')
      end
      params
    end
  end

  class RouteSet(T)
    EXTRACT_FIXED_PREFIX = /^([^:*(]*)/

    def initialize
      # @routes = Hash(String, Array(Route(T))).new
      @routes = Array({String, Array(Route(T))}).new
    end

    def add(path : String, payload : T)
      path = normalize(path)
      path =~ EXTRACT_FIXED_PREFIX

      # routes = @routes[$1] ||= [] of Route(T)

      prefix = $1
      routes = @routes.find { |(k, _)| k == prefix }.try(&.last)

      unless routes
        routes = [] of Route(T)
        @routes << {prefix, routes}
      end

      routes << Route(T).new(path, payload)
    end

    def each(path : String, &block : Match(T) ->) : Nil
      path = normalize(path)

      @routes.each do |(prefix, routes)|
        next unless path.starts_with?(prefix)

        routes.each do |route|
          if params = route.matches?(path)
            yield Match(T).new(route.payload, params)
          end
        end

        # break
      end
    end

    def find_one(path : String) : Match(T)?
      each(path) { |match| return match }
    end

    def find_all(path : String) : Array(Match(T))
      matches = [] of Match(T)
      each(path) { |match| matches << match }
      matches
    end

    private def normalize(path : String) : String
      unless path.starts_with?('/')
        path = "/#{path}"
      end

      if path == "/"
        path
      else
        path.chomp('/')
      end
    end
  end

  # routes = RouteSet(Symbol).new
  # routes.add("/posts", :posts)
  # routes.add("/posts/new", :new_post)
  # routes.add("/posts/:id", :post)
  # routes.add("/posts/:id/edit(.:format)", :edit_post)
  # routes.add("/api/*catch", :api_catch)
  # routes.add("/prefix/*catch/suffix", :prefix_catch)
  # routes.add("*path", :catch_all)

  # p routes.find_one("/posts")
  # p routes.find_one("/posts/123")
  # p routes.find_one("/posts/hello")
  # p routes.find_one("/posts/new")
  # p routes.find_one("/posts/456/edit")
  # p routes.find_one("/posts/456/edit.json")
  # p routes.find_one("/api/whatever/filename.jpg")
  # p routes.find_one("/whatever/file.pdf")
  # p routes.find_one("/prefix/whatever/file.pdf/suffix")
end
