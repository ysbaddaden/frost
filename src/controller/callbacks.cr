class Frost::Controller
  module Callbacks
    # Generates a `#before_action` method, making sure to call `super` before
    # executing the block passed to the macro.
    macro before_action
      def before_action
        super
        {{yield}}
      end
    end

    # Generates an `#after_action` method, making sure to call `super` after
    # executing the block passed to the macro.
    macro after_action
      def after_action
        {{yield}}
        super
      end
    end

    # This method will be invoked before the action, you can override it to run
    # any arbitrary things before the action. Overrides should call `super` to
    # make sure that the ancestor's `#before_action` method is invoked, unless
    # it's a deliberate choice to not call it.
    #
    # If the controller rendered anything, redirected or called `#head` then
    # the request will stop being processed. None of `#around_action`, the
    # actual action or `#after_action` will be called.
    def before_action
    end

    # This method will be invoked with a block that will call the actual
    # controller action. You must call `super { yield }` to actually call the
    # action.
    def around_action(&)
      yield
    end

    # This method will be invoked after the action and after `#around_action`
    # has been called. You can override it to run any arbitrary things after the
    # action. Overrides should call `super` to make sure that the ancestor's
    # `#after_action` method is invoked, unless it's a deliberate choice to not
    # call it.
    def after_action
    end

    # Invokes the `#before_action` method, then `#around_action` that must
    # yield to run the provided callback to invoke the action. Eventually calls
    # the `#after_action` method.
    def run_action(&)
      self.before_action
      return if already_rendered?

      around_action { yield }

      self.after_action
    end
  end
end
