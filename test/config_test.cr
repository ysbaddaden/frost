require "syn/mutex"
require "./test_helper"
require "../src/config"

class Frost::ConfigTest < Minitest::Test
  class MyConf < Frost::Config
    self.config_path = File.expand_path("./config", __DIR__)
    attribute my_conf_public_path : String
    attribute my_conf_database_url : String
    attribute my_conf_integer : Int64
    attribute my_conf_float : Float64
    attribute my_conf_bool : Bool
  end

  @@mutex = Syn::Mutex.new(:unchecked)

  def setup
    @@mutex.lock
  end

  def teardown
    @@mutex.unlock
  end

  def test_setup_from_env
    config = MyConf.setup_from_env(Frost::Env.new("test"))
    assert_equal "default", config.my_conf_public_path
    assert_equal "postgres://", config.my_conf_database_url
  end

  def test_nil
    config = MyConf.setup_from_env(Frost::Env.new("development"))
    assert_equal "test/public", config.my_conf_public_path
    assert_nil config.my_conf_database_url?
    assert_raises(NilAssertionError) { config.my_conf_database_url }
  end

  def test_load_overrides
    ENV["MY_CONF_PUBLIC_PATH"] = "custom"
    ENV["MY_CONF_DATABASE_URL"] = "mysql://"
    ENV["MY_CONF_INTEGER"] = Random::DEFAULT.next_int.to_s
    ENV["MY_CONF_FLOAT"] = Random::DEFAULT.next_float.to_s

    config = MyConf.setup_from_env(Frost::Env.new("test"))
    assert_equal "custom", config.my_conf_public_path
    assert_equal "mysql://", config.my_conf_database_url
    assert_equal ENV["MY_CONF_INTEGER"], config.my_conf_integer.to_s
    assert_equal ENV["MY_CONF_FLOAT"], config.my_conf_float.to_s
  ensure
    ENV.delete("MY_CONF_PUBLIC_PATH")
    ENV.delete("MY_CONF_DATABASE_URL")
    ENV.delete("MY_CONF_INTEGER")
    ENV.delete("MY_CONF_FLOAT")
  end

  def test_load_overrides_bools
    ENV["MY_CONF_BOOL"] = {"1", "true"}.sample
    config = MyConf.setup_from_env(Frost::Env.new("test"))
    assert_equal true, config.my_conf_bool

    ENV["MY_CONF_BOOL"] = {"0", "false"}.sample
    config = MyConf.setup_from_env(Frost::Env.new("test"))
    assert_equal false, config.my_conf_bool

    ENV["MY_CONF_BOOL"] = "invalid"
    assert_raises { MyConf.setup_from_env(Frost::Env.new("test")) }
  ensure
    ENV.delete("MY_CONF_BOOL")
  end
end
