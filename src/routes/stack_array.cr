module Frost::Routes
  # nodoc
  struct StackArray(T, N)
    def initialize
      @pos = 0
      @buffer = uninitialized StaticArray(T, N)
    end

    def [](index : Int32) : T
      @buffer[index]
    end

    def <<(node : T)
      if @pos < N
        @buffer.to_unsafe[@pos] = node
        @pos += 1
      else
        raise "ERROR: overflow"
      end
    end

    def each(&block : T ->)
      @pos.times do |index|
        yield @buffer.to_unsafe[index]
      end
    end

    def each_with_index(&block : T ->)
      @pos.times do |index|
        yield @buffer.to_unsafe[index], index
      end
    end

    def map(& : T -> U) : Array(U) forall U
      ary = [] of U
      each { |node| ary << yield node }
      ary
    end

    def truncate(index)
      @pos = index.clamp(0, @pos)
    end

    def size
      @pos
    end

    def last
      if @pos > 0
        @buffer[@pos - 1]
      else
        raise IndexError.new
      end
    end
  end

end
