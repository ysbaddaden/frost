module Trail
  class Controller
    # TODO: stop processing if a callback returns false or rendered
    # TODO: :only and :except filters to selectively run callbacks
    module Filtering
      {{ run "../support/callbacks", "before,around,after", "action" }}

      def run_action
        run_before_action_callbacks
        run_around_action_callbacks { yield }
        run_after_action_callbacks
      end
    end
  end
end
