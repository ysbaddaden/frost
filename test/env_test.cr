require "./test_helper"

class Frost::EnvTest < Minitest::Test
  def test_development
    env = Env.new("development")
    assert_equal "development", env.name
    assert env.development?
    refute env.production?
    refute env.test?
  end

  def test_test
    env = Env.new("test")
    assert_equal "test", env.name
    refute env.development?
    refute env.production?
    assert env.test?
  end

  def test_production
    env = Env.new("production")
    assert_equal "production", env.name
    refute env.development?
    assert env.production?
    refute env.test?
  end

  def test_custom_environment
    env = Env.new("staging")
    assert_equal "staging", env.name
    refute env.development?
    refute env.production?
    refute env.test?
    assert env.staging?
  end
end
