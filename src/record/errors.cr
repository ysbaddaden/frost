module Trail
  class Record
    class Error < Exception
    end

    #class ConnectionError < Exception
    #end

    #class RangeError < Error
    #end

    class RecordNotFound < Error
    end

    #class RecordInvalid < Error
    #end
  end
end
