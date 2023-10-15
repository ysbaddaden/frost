require "yaml"
require "./env"

# Central place to store your application configuration.
#
# YAML Configuration
#
# Configuration files are YAML files and expected to be under `$PWD/config` and
# named by the environment(s) your application is meant to run (see
# `Frost::Env`). For example if the current environment is `development` then it
# will try to load `config/development.yaml` then `config/development.yml` and
# finally fall back to an empty configuration.
#
# Environment variables
#
# It will then load configuration from environment variables. The environment
# variables are the attribute name but uppercase.
#
# Secrets
#
# Supports docker-like secrets. If a file named with the attribute name exists
# in the secrets folder (`/run/secrets` by default) it will be read.
#
# You can also specify an environment variable ending with `_FILE` that points
# to the secret file to read.
#
# Example:
#
# ```
# class App::Config < Frost::Config
#   attribute public_path : String
#   attribute database_url : String
# end
#
# config = App::Config.setup_from_env
# config.public_path # => may raise
# if public_path = config.public_path? # => returns a nilable.
# ```
#
# In the above example the associated configuration file is expected to be a map
# of each config attribute. Attributes aren't required, and may be missing from
# the file.
#
# ```yaml
# public_path: "public"
# database_url: "postgres://postgres@/db_development"
# ```
#
# The environment variables are the uppercase attribute names:
#
# ```shell
# PUBLIC_PATH="public"
# DATABASE_URL="postgres://postgres@/db_test"
# ```
abstract class Frost::Config
  include YAML::Serializable

  # :nodoc:
  annotation Attribute; end

  class_property config_path : String = "config"
  class_property secrets_path : String = "/run/secrets"

  # Declares an attribute. The behavior is similar to the `getter!` macro.
  # Only String, Int64, Float64 and Bool types are supported.
  macro attribute(decl)
    {% unless decl.is_a?(TypeDeclaration) %}
      {% raise "Frost::Config#attribute expects a TypeDeclaration" %}
    {% end %}
    {% unless {String.id, Int64.id, Float64.id, Bool.id}.includes?(decl.type.id) %}
      {% raise "Frost::Config#attribute can only be a String, Int64, Float64 or Bool, not a #{decl.type}" %}
    {% end %}

    @[Attribute]
    @{{decl.var}} : {{decl.type}} | Nil

    def {{decl.var}} : {{decl.type}}
      @{{decl.var}}.not_nil!("{{@type}}\#{{decl.var}} cannot be nil")
    end

    def {{decl.var}}? : {{decl.type}} | Nil
      @{{decl.var}}
    end
  end

  def initialize
    # needed because YAML::Serializable injects a new(YAML::Context, YAML::Nodes::Node) method
  end

  # Loads configuration from the `config` folder then overrides them from `ENV`.
  def self.setup_from_env(env : Frost::Env = Frost.env) : self
    config =
      if File.exists?(path = File.join(config_path, "#{env}.yaml"))
        File.open(path, "r") { |io| from_yaml(io) }
      elsif File.exists?(path = File.join(config_path, "#{env}.yml"))
        File.open(path, "r") { |io| from_yaml(io) }
      else
        new
      end
    config.load_overrides
    config
  end

  protected def load_overrides : Nil
    {% for ivar in @type.instance_vars %}
      {% if ivar.annotation(Attribute) %}
        {% types = ivar.type.union_types %}
        {% if    types.includes?(String)  %} env({{ivar.name.symbolize}})
        {% elsif types.includes?(Int64)   %} env_int({{ivar.name.symbolize}})
        {% elsif types.includes?(Float64) %} env_float({{ivar.name.symbolize}})
        {% elsif types.includes?(Bool)    %} env_bool({{ivar.name.symbolize}})
        {% end %}
      {% end %}
    {% end %}
  end

  macro env(key)
    if %value = env_read({{key.id.stringify}})
      @{{key.id}} = %value
    end
  end

  macro env_int(key)
    if %value = env_read({{key.id.stringify}})
      @{{key.id}} = %value.to_i64
    end
  end

  macro env_float(key)
    if %value = env_read({{key.id.stringify}})
      @{{key.id}} = %value.to_f64
    end
  end

  macro env_bool(key)
    if %value = env_read({{key.id.stringify}})
      case %value
      when "1", "true"
        @{{key.id}} = true
      when "0", "false"
        @{{key.id}} = false
      else
        raise %(Error: invalid config bool value for {{key.id}}: expected "1", "0", "true" or "false" but got #{%value.inspect})
      end
    end
  end

  @[AlwaysInline]
  def env_read(key : String) : String?
    env_key = key.upcase

    if value = ENV[env_key]?.presence
      return value
    end

    secret_path = File.join(self.class.secrets_path, key)
    return File.read(secret_path) if File.exists?(secret_path)

    if value = ENV["#{env_key}_FILE"]?.presence
      File.read(value).presence
    end
  end
end
