module Frost::Routes
  class Route(T)
    getter key : String
    getter children : Array(Route(T))?
    @payload : T?
    @param_name : String?
    property format : String?
    @glob = false
    @has_param_child = false

    def initialize(@key : String, @children : Array(Route(T))? = nil)
      if @key.starts_with?(':')
        @param_name = @key.lstrip(':')
      elsif @key.starts_with?('*')
        @glob = true
        @param_name = @key.lstrip('*')
      end
    end

    def param? : Bool
      !@param_name.nil?
    end

    def param_name : String
      @param_name.not_nil!
    end

    def glob? : Bool
      @glob
    end

    def payload : T
      @payload.not_nil!
    end

    def payload? : T?
      @payload
    end

    def payload=(payload : T?)
      @payload = payload
    end

    def has_param_child? : Bool
      @has_param_child
    end

    def add(segment : String) : Route(T)
      if children = @children
        if node = children.find { |n| n.key == segment }
          return node
        end
      else
        children = @children = [] of Route(T)
      end

      node = Route(T).new(segment)

      # sort children so that param segments are tested _after_ fixed segments,
      # otherwise we could wrongly match a param route instead of a specific
      # path
      if !node.param? && (index = children.index(&.param?))
        children.insert(index, node)
      else
        children << node
      end

      @has_param_child = true if node.param?

      node
    end

    def add_with_format(node : Route(T)) : Nil
      if children = @children
        return if children.includes?(node)

        # sort children so that segments with a format are tested before the
        # same segment but without a format (always matches)
        if index = children.index { |n| n.key == node.key && !n.format }
          children.insert(index, node)
        else
          children << node
        end
      else
        @children = [node]
      end

      @has_param_child = true if node.param?
    end

    def dup : Route(T)
      node = super
      node.payload = nil
      node
    end
  end
end
