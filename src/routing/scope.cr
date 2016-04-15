module Frost
  module Routing
    # TODO: defaults
    module Scope
      def scope(path = nil, name = nil, as = nil, controller = nil)
        with_scope do |constraints|
          if path
            unless path.starts_with?("/")
              path = "/#{ path }"
            end

            if constraints[:path]?
              constraints[:path] += path.chomp('/')
            else
              constraints[:path] = path.chomp('/')
            end
          end

          if name
            if constraints[:name]?
              constraints[:name] += "/#{ name }"
            else
              constraints[:name] = name.to_s
            end
          end

          if as
            if constraints[:as]?
              constraints[:as] += "_#{ as }"
            else
              constraints[:as] = as.to_s
            end
          end

          if controller
            constraints[:controller] = controller.to_s
          end

          yield
        end
      end

      def namespace(name)
        scope(path: "/#{ name }", name: name.to_s, as: name.to_s) { yield }
      end

      private def with_scope
        constraints = current_scope.dup
        scopes.push(constraints)

        begin
          yield constraints
        ensure
          scopes.pop
        end
      end

      private def previous_scope
        scopes[-2]
      end

      private def current_scope
        scopes.last
      end

      private def scopes
        Scope.scopes
      end

      protected def self.scopes
        @@scopes ||= [{} of Symbol => String]
      end
    end
  end
end
