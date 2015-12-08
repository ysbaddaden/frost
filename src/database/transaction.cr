module Trail
  module Database
    class Transaction
      # FIXME: stack isn't thread-safe (is it even fiber-safe?)

      @@stack = [] of Transaction

      def self.stack
        @@stack
      end

      def self.any?
        stack.any?
      end

      def self.current
        stack.last
      end

      def initialize(@conn)
        @committed = @rolledback = false
        @count = stack.size
        stack << self
      end

      def savepoint?
        @count > 0
      end

      def committed?
        @committed
      end

      def rolledback?
        @rolledback
      end

      def completed?
        committed? || rolledback?
      end

      def begin
        if savepoint?
          @conn.execute("SAVEPOINT #{ savepoint }")
        else
          @conn.execute("BEGIN")
        end
      end

      def rollback
        if completed?
          raise "can't rollback transaction: already completed"
        end

        if savepoint?
          @conn.execute("ROLLBACK TO SAVEPOINT #{ savepoint }")
        else
          @conn.execute("ROLLBACK")
        end

        @rolledback = true
      ensure
        stack.delete(self)
      end

      def commit
        if completed?
          raise "can't commit transaction: already completed"
        end

        if savepoint?
          @conn.execute("RELEASE SAVEPOINT #{ savepoint }")
        else
          @conn.execute("COMMIT")
        end

        @committed = true
      ensure
        stack.delete(self)
      end

      private def savepoint
        "trail_record_#{ @count }"
      end

      private def stack
        self.class.stack
      end
    end
  end
end
