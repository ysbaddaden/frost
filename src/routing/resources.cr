require "../support/core_ext/string"

module Frost
  module Routing
    # TODO: "as" argument
    module Resources
      RESOURCES_ACTIONS = %w(index show new edit create update replace destroy)
      RESOURCE_ACTIONS = %w(show new edit create update replace destroy)

      def resources(name, only = nil, except = nil, controller = nil)
        resources(name, only: only, except: except, controller: controller) {}
      end

      def resource(name, only = nil, except = nil, controller = nil)
        resource(name, only: only, except: except, controller: controller) {}
      end

      def resources(name, only = nil, except = nil, controller = nil)
        actions = RESOURCES_ACTIONS.dup
        plural = name.to_s
        singular = plural.singularize
        controller ||= plural

        case only
        when Symbol, String
          actions &= [only.to_s]
        when Array
          actions &= only.map(&.to_s)
        end

        case except
        when Symbol, String
          actions.delete(except.to_s)
        when Array
          actions -= except.map(&.to_s)
        end

        if _as = current_scope[:as]?
          as_plural = "#{_as}_#{ plural }"
          as_singular = "#{_as}_#{ singular }"
        else
          as_plural = plural
          as_singular = singular
        end

        with_scope do |constraints|
          constraints[:resources_member_path] = "#{ constraints[:path]? }/#{ plural }/:id"
          constraints[:resources_collection_path] = "#{ constraints[:path]? }/#{ plural }"

          scope(path: "/#{ plural }/:#{ singular }_id", as: singular, controller: controller) do
            yield
          end
        end

        if actions.includes?("index")
          get "/#{ plural }(.:format)", "#{ controller }#index", as: as_plural
        end

        if actions.includes?("new")
          get "/#{ plural }/new(.:format)", "#{ controller }#new", as: "new_#{ as_singular }"
        end

        if actions.includes?("show")
          get "/#{ plural }/:id(.:format)", "#{ controller }#show", as: as_singular
        end

        if actions.includes?("edit")
          get "/#{ plural }/:id/edit(.:format)", "#{ controller }#edit", as: "edit_#{ as_singular }"
        end

        if actions.includes?("create")
          post "/#{ plural }(.:format)", "#{ controller }#create", as: as_plural
        end

        if actions.includes?("update")
          patch "/#{ plural }/:id(.:format)", "#{ controller }#update", as: as_singular
        end

        if actions.includes?("replace")
          put "/#{ plural }/:id(.:format)", "#{ controller }#replace", as: as_singular
        end

        if actions.includes?("destroy")
          delete "/#{ plural }/:id(.:format)", "#{ controller }#destroy", as: as_singular
        end
      end

      def resource(name, only = nil, except = nil, controller = nil)
        actions = RESOURCE_ACTIONS.dup
        singular = name.to_s
        controller ||= singular.pluralize

        case only
        when Symbol, String
          actions &= [only.to_s]
        when Array
          actions &= only.map(&.to_s)
        end

        case except
        when Symbol, String
          actions.delete(except.to_s)
        when Array
          actions -= except.map(&.to_s)
        end

        if _as = current_scope[:as]?
          as_singular = "#{_as}_#{ singular }"
        else
          as_singular = singular
        end

        scope(path: "/#{ singular }", as: singular, controller: controller) do
          yield
        end

        if actions.includes?("show")
          get "/#{ singular }(.:format)", "#{ controller }#show", as: as_singular
        end

        if actions.includes?("new")
          get "/#{ singular }/new(.:format)", "#{ controller }#new", as: "new_#{ as_singular }"
        end

        if actions.includes?("edit")
          get "/#{ singular }/edit(.:format)", "#{ controller }#edit", as: "edit_#{ as_singular}"
        end

        if actions.includes?("create")
          post "/#{ singular }(.:format)", "#{ controller }#create", as: as_singular
        end

        if actions.includes?("update")
          patch "/#{ singular }(.:format)", "#{ controller }#update", as: as_singular
        end

        if actions.includes?("replace")
          put "/#{ singular }(.:format)", "#{ controller }#replace", as: as_singular
        end

        if actions.includes?("destroy")
          delete "/#{ singular }(.:format)", "#{ controller }#destroy", as: as_singular
        end
      end

      def member
        if path = current_scope[:resources_member_path]?
          with_scope do |constraints|
            constraints[:path] = path
            yield
          end
        else
          yield
        end
      end

      def collection
        if path = current_scope[:resources_collection_path]?
          with_scope do |constraints|
            constraints[:path] = path
            yield
          end
        else
          yield
        end
      end
    end
  end
end
