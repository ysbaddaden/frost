require "syn/mutex"
require "./test_helper"
require "../src/config"

class Frost::ConfigTest < Minitest::Test
  class MyConf < Frost::Config
    self.config_path = File.expand_path("./config", __DIR__)
    self.secrets_path = File.expand_path("./config/secrets", __DIR__)

    attribute my_conf_public_path : String
    attribute my_conf_database_url : String
    attribute my_conf_integer : Int64
    attribute my_conf_float : Float64
    attribute my_conf_bool : Bool
    attribute my_conf_api_secret : String
  end

  @@mutex = Syn::Mutex.new(:unchecked)

  def setup
    @@mutex.lock
  end

  def teardown
    @@mutex.unlock
  end

  def test_yaml_configuration
    config = MyConf.setup_from_env(Frost::Env.new("test"))
    assert_equal "default", config.my_conf_public_path
    assert_equal "postgres://", config.my_conf_database_url
  end

  def test_env_overrides
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

  def test_secret_env_file
    tmp = File.tempfile
    tmp.write(secret = Random::DEFAULT.random_bytes(32))
    tmp.close

    ENV["MY_CONF_API_SECRET_FILE"] = tmp.path
    config = MyConf.setup_from_env(Frost::Env.new("test"))
    assert_equal secret, config.my_conf_api_secret.to_slice
  ensure
    File.delete(tmp.path) if tmp
    ENV.delete("MY_CONF_API_SECRET_FILE")
  end

  def test_secrets_folder
    path = File.join(MyConf.secrets_path, "my_conf_api_secret")
    File.write(path, secret = Random::DEFAULT.random_bytes(32))

    config = MyConf.setup_from_env(Frost::Env.new("test"))
    assert_equal secret, config.my_conf_api_secret.to_slice
  ensure
    File.delete(path) if path && File.exists?(path)
  end

  def test_bools
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

  def test_nilables
    config = MyConf.setup_from_env(Frost::Env.new("development"))
    assert_equal "test/public", config.my_conf_public_path
    assert_nil config.my_conf_database_url?
    assert_raises(NilAssertionError) { config.my_conf_database_url }
  end
end
