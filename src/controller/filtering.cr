module Trail
  class Controller
    # Run action filters before, after and around the action.
    #
    # A controller may define the `before_action`, `after_action` and
    # `around_action(&block)` methods to execute code around all its actions.
    #
    # If `before_action` returns false or renders or redirects, the filter chain
    # will be halted immediately, and neither the action, the `around_action`
    # method nor the `after_action` method will be invoked.
    #
    # Examples:
    # ```
    # class PagesController < ApplicationController
    #   def before_action
    #     return false unless user_signed_in?
    #   end
    #
    #   def around_action
    #     I18n.with_locale(current_user.locale) { yield }
    #   end
    #
    #   def after_action
    #     if q = params["q"]?
    #       response.body = replace_search_marks(response.body, q)
    #     end
    #   end
    # end
    # ```
    module Filtering
      #{{ run "../support/callbacks", "before,around,after", "action" }}

      def run_action
        if self.responds_to?(:before_action)
          return if self.before_action == false
          return if already_rendered?
        end

        if self.responds_to?(:around_action)
          self.around_action { yield }
        else
          yield
        end

        if self.responds_to?(:after_action)
          self.after_action
        end
      end
    end
  end
end
