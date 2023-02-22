require "uri"
require "./params"
require "./route"
require "./stack_array"

module Frost::Routes
  record Match(T),
    payload : T,
    params : Params

  class RouteSet(T)
    # nodoc
    MAX_SEGMENTS = 12

    def initialize
      @tree = Route(T).new("")
    end

    def add(path : String, payload : T) : Nil
      path, format = extract_format(path)
      node = parent = @tree

      path.split('/', remove_empty: true) do |segment|
        parent = node
        node = parent.add(segment)
      end

      if node.format != format
        node = node.dup if node.payload?
        node.format = format
        parent.add_with_format(node)
      elsif format
        node.format = format
      end

      raise "ERROR: a route for #{path} has already been declared" if node.payload?
      node.payload = payload
    end

    def find(path : String) : Match(T)?
      path, format = extract_format(path)

      if path == "/"
        return unless payload = @tree.payload?
        params = Params.new
      else
        segments = StackArray(String, MAX_SEGMENTS).new
        path.split('/', MAX_SEGMENTS, remove_empty: true) { |s| segments << s }

        parts = StackArray(Route(T), MAX_SEGMENTS).new
        return unless try_branch(@tree, pointerof(segments), 0, pointerof(parts), format)
        return unless payload = parts.last.payload?

        params = extract_params(pointerof(segments), pointerof(parts), format)
      end

      Match(T).new(payload, params)
    end

    @[AlwaysInline]
    private def extract_format(path) : {String, String?}
      if dot = path.rindex('.')
        slash = path.rindex('/')

        if slash.nil? || slash < dot
          return {path[0...dot], path[(dot + 1 )..-1]}
        end
      end
      {path, nil}
    end

    @[AlwaysInline]
    private def extract_params(segments, parts, format) : Params
      params = Params.new

      parts.value.each_with_index do |node, index|
        if node.glob?
          value = String.build do |str|
            index.upto(segments.value.size - 1) do |i|
              str << '/' unless i == index
              str << segments.value[i]
            end
            if format
              str << '.'
              str << format
            end
          end
          params[node.param_name] = value
        elsif node.param?
          value = segments.value[index]
          value = URI.decode(value) if value.includes?('%')
          params[node.param_name] = value
        end
      end

      if format
        params["format"] = format
      end

      params
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def try_branch(node, segments, index, parts, format) : Bool
      original_index = index
      parts.value << node unless index == 0

      while index < segments.value.size
        return false unless children = node.children
        is_last = index == segments.value.size - 1

        found = children.find do |child|
          if child.param?
            if child.glob?
              # abort: collect all remaining segments
              parts.value << child
              return true
            elsif child.children
              # abort: a nested child matched
              if try_branch(child, segments, index + 1, parts, format)
                return true
              end
            elsif is_last
              # select leaf node
              try_route_constraints
            else
              # abort: no children despite having more segments to match
              false
            end
          elsif child.key == segments.value[index]
            # select matching node
            if is_last
              try_route_constraints
            elsif node.has_param_child?
              # try the current branch, allowing to backtrack if a branch
              # doesn't match (because of glob routes)
              if try_branch(child, segments, index + 1, parts, format)
                return true
              end
            else
              # select the segment
              true
            end
          end
        end

        if found
          parts.value << (node = found)
        else
          # branch led to no match: backtrack!
          parts.value.truncate(original_index - 1)
          return false
        end

        index += 1
      end

      true
    end

    private macro try_route_constraints
      (format && format == child.format) || child.format.nil?
    end
  end
end
