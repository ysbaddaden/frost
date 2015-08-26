module PG
  class TrailResult
    getter :fields

    def initialize(@res)
      @fields = Array(PG::Result::Field).new(nfields) do |i|
        PG::Result::Field.new_from_res(res, i)
      end
    end

    def finalize
      LibPQ.clear(res)
    end

    def any?
      ntuples(res) > 0
    end

    def each_row
      ntuples.times { |row| yield row }
    end

    def each_field(row)
      fields.each_with_index do |field, col|
        val_ptr = LibPQ.getvalue(res, row, col)
        value = if val_ptr.value == 0 && LibPQ.getisnull(res, row, col)
                  nil
                else
                  field.decoder.decode(val_ptr)
                end
        yield field.name, value
      end
    end

    private getter :res

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
