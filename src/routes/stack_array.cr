module Frost::Routes
  # nodoc
  struct StackArray(T, N)
    def initialize
      @pos = 0
      @buffer = uninitialized StaticArray(T, N)
    end

    def [](index : Int32) : T
      if index < @pos
        @buffer.to_unsafe[index]
      else
        raise IndexError.new
      end
    end

    def <<(node : T) : Nil
      if @pos < N
        @buffer.to_unsafe[@pos] = node
        @pos += 1
      else
        raise "ERROR: overflow"
      end
    end

    def each(& : T ->) : Nil
      @pos.times do |index|
        yield @buffer.to_unsafe[index]
      end
    end

    def each_with_index(& : T ->) : Nil
      @pos.times do |index|
        yield @buffer.to_unsafe[index], index
      end
    end

    def map(& : T -> U) : Array(U) forall U
      ary = [] of U
      each { |node| ary << yield node }
      ary
    end

    def truncate(index) : Nil
      @pos = index.clamp(0, @pos)
    end

    def size : Int32
      @pos
    end

    def last : T
      if @pos > 0
        @buffer[@pos - 1]
      else
        raise IndexError.new
      end
    end
  end

end
