require "../test_helper"

class Frost::Controller::CallbacksTest < Minitest::Test
  include Frost::Controller::TestHelper

  class XController < Controller
    @@callbacks = [] of Symbol

    def self.callbacks
      @@callbacks
    end

    before_action do
      @@callbacks << :before_action
      head :no_content if params["render_before"]?
    end

    after_action do
      @@callbacks << :after_action
    end

    def index
      @@callbacks << :index
      head :ok
    end

    def around_action(&)
      @@callbacks << :around_action_in
      super { yield }
    ensure
      @@callbacks << :around_action_out
    end
  end

  @@mutex = Mutex.new

  def setup
    @@mutex.lock
  end

  def teardown
    XController.callbacks.clear
    @@mutex.unlock
  end

  def test_callbacks_execution_order
    call :index

    assert_equal %i[
      before_action
      around_action_in
      index
      around_action_out
      after_action
    ], XController.callbacks
  end

  def test_render_in_before_action_interrupts_action
    call :index, params: { "render_before" => "1" }
    assert_equal %i[before_action], XController.callbacks
  end
end
