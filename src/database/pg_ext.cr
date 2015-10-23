module PG
  class TrailResult
    struct Row
      def initialize(@result, @row)
      end

      def each
        @result.fields.each_with_index do |field, col|
          val_ptr = LibPQ.getvalue(@result.res, @row, col)
          value = if val_ptr.value == 0 && LibPQ.getisnull(@result.res, @row, col)
                    nil
                  else
                    size = LibPQ.getlength(@result.res, @row, col)
                    field.decoder.decode(val_ptr.to_slice(size))
                  end
          yield field.name, value
        end
      end
    end

    getter :fields

    # :nodoc:
    getter :res

    def initialize(@res)
      @fields = Array(PG::Result::Field).new(nfields) do |i|
        PG::Result::Field.new_from_res(res, i)
      end
    end

    def finalize
      LibPQ.clear(res)
    end

    def any?
      ntuples > 0
    end

    def each
      ntuples.times { |i| yield Row.new(self, i) }
    end

    private def ntuples
      LibPQ.ntuples(res)
    end

    private def nfields
      LibPQ.nfields(res)
    end
  end

  class Connection
    def trail_exec(query : String)
      trail_exec(query, [] of PG::PGValue)
    end

    def trail_exec(query : String, params)
      TrailResult.new(libpq_exec(query, params))
    end
  end
end
