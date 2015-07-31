module Trail
  module Database
    class Error < Exception
    end

    class ConnectionError < Error
    end

    class StatementInvalid < Error
    end
  end
end
