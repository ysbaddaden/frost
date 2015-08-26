require "ecr"

module Trail
  class View
    class ECR
      include ::ECR

      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      def self.process_file(filename, buffer_name = "__buf__")
        new(File.read(filename), filename, buffer_name).process
      end

      def self.process_string(template, filename, buffer_name = "__buf__")
        new(template, filename, buffer_name).process
      end

      getter :lexer, :filename, :buffer_name

      def initialize(template, @filename, @buffer_name = "__buf__")
        @lexer = Lexer.new(template)
      end

      def process
        String.build do |str|
          loop do
            token = lexer.next_token

            case token.type
            when :STRING  then add_string(str, token)
            when :OUTPUT  then add_output(str, token)
            when :CONTROL then add_control(str, token)
            when :EOF     then break
            end
          end
        end
      end

      def add_string(str, token)
        str << buffer_name
        str << " << "
        token.value.inspect(str)
        str << "\n"
      end

      def add_output(str, token)
        if BLOCK_EXPR =~ token.value
          str << buffer_name
          str << " << "
          append_loc(str, filename, token)
          str << token.value
          str << "\n"
        else
          str << "("
          append_loc(str, filename, token)
          str << token.value
          str << ").to_s(" << buffer_name << ")\n"
        end
      end

      def add_control(str, token)
        append_loc(str, filename, token)
        str << token.value
        str << "\n"
      end
    end
  end
end
