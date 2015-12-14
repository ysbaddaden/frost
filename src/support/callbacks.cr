module Frost
  module Support
    # NOTE: no longer work on Crystal > 0.7.5 (inherited hook is ran before
    #       evaluating the class body, so no longer can collect callbacks and
    #       generate methods)
    class Callbacks
      # :nodoc:
      HOOK_NAMES = %w(before around after)

      def initialize(@names)
        @hooks = HOOK_NAMES & @names.shift.split(",")
      end

      def generate_constants(name, str)
        @hooks.each do |hook|
          constant = constant_name(hook, name)
          str << "\n# :nodoc:\n"
          str << "#{ constant } = {} of String => Array(String)\n"
        end
        str << "\n"
      end

      def generate_macros(name, str)
        @hooks.each do |hook|
          constant = constant_name(hook, name)

          str << "macro #{ hook }_#{ name }(*names)\n"
          str << "  {% for name in names %}\n"
          str << "    {% #{ constant }[@type.name] = [] of String unless #{ constant }[@type.name] %}\n"
          str << "    {% #{ constant }[@type.name].push(name.id.stringify) %}\n"
          str << "  {% end %}\n"
          str << "end\n\n"
        end
      end

      def generate_default_methods(name, str)
        @hooks.each do |hook|
          str << "protected def run_#{ hook }_#{ name }_callbacks\n"
          str << "  yield\n" if hook == "around"
          str << "end\n\n"
        end
      end

      def generate_run_macros(name, str)
        @hooks.each do |hook|
          constant = constant_name(hook, name)

          str << "# :nodoc:\n"
          str << "macro generate_run_#{ hook }_#{ name }_callbacks\n"
          str << "  protected def run_#{ hook }_#{ name }_callbacks\n"

          if hook == "around"
            generate_around_macro_contents(constant, str)
          else
            generate_regular_macro_contents(constant, str)
          end

          str << "    nil\n"
          str << "  end\n"
          str << "end\n\n"
        end
      end

      private def generate_around_macro_contents(constant, str)
        str << "    {% acc = \"super { yield }\" %}\n"
        str << "    {% #{ constant }[@type.name].map { |name| acc = \"\#{ name.id } { \#{ acc.id } }\"} %}\n"
        str << "    {{ acc.id }}\n"
      end

      private def generate_regular_macro_contents(constant, str)
        str << "    super\n\n"
        str << "    {% for name in #{ constant }[@type.name] %}\n"
        str << "      {{ name.id }}\n"
        str << "    {% end %}\n\n"
      end

      private def constant_name(hook, name)
        "#{ hook.upcase }_#{ name.upcase }_HOOKS"
      end

      def to_crystal_s
        String.build do |str|
          @names.each do |name|
            generate_constants(name, str)
            generate_default_methods(name, str)
            generate_macros(name, str)
            generate_run_macros(name, str)

            str << "# :nodoc:\n"
            str << "macro generate_run_#{ name }_callbacks\n"

            @hooks.each do |hook|
              constant = constant_name(hook, name)

              str << "  {% unless @type.methods.map(&.name.stringify).any? { |m| m == \"run_#{ hook }_#{ name }_callbacks\" } %}\n"
              str << "    {% if #{ constant }[@type.name] && !#{ constant }[@type.name].empty? %}\n"
              str << "      generate_run_#{ hook }_#{ name }_callbacks\n"
              str << "    {% end %}\n"
              str << "  {% end %}\n\n"
            end

            str << "end\n\n"
          end
        end
      end
    end
  end

  at_exit do
    puts Support::Callbacks.new(ARGV).to_crystal_s
  end
end
