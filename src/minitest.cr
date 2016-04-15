require "minitest/autorun"
require "./record/fixtures"
require "./controller/test"

class Minitest::Test
  include Frost::Record::TransactionalFixtures
  @transaction : Frost::Database::Transaction?

  def before_setup
    super

    if self.responds_to?(:preload_fixtures)
      preload_fixtures
    end

    @transaction = Frost::Record.connection.transaction
  end

  def after_teardown
    clear_fixtures_cache
    super
  ensure
    if transaction = @transaction
      transaction.rollback unless transaction.completed?
    end
  end
end
