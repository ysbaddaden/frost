module Frost
  abstract class Controller
    # A controller may define the `before_action` and `after_action` methods to
    # execute code around all its actions.
    #
    # Example:
    # ```
    # class PagesController < ApplicationController
    #   def before_action
    #     return false unless user_signed_in?
    #   end
    #
    #   def after_action
    #     if q = params["q"]?
    #       response.body = replace_search_marks(response.body, q)
    #     end
    #   end
    # end
    # ```
    #
    # Running an action actually first runs `before_action`. If `before_action`
    # returns false, renders or redirects, the chain will be halted immediately,
    # Otherwise the actual action will be run, and eventually `after_action`.
    module Filtering
      #{{ run "../support/callbacks", "before,around,after", "action" }}

      # Wraps the execution of a controller action, running the filter methods
      # if they're defined.
      def run_action
        if self.responds_to?(:before_action)
          return if self.before_action == false
          return if already_rendered?
        end

        yield

        if self.responds_to?(:after_action)
          self.after_action
        end

        nil
      end
    end
  end
end
