require "ecr/macros"
require "colorize"
require "secure_random"

lib LibC
  fun chmod(path : Char*, mode : ModeT) : Int
  fun fchmod(path : Int, mode : ModeT) : Int
end

# :nodoc:
class File
  # :nodoc:
  def self.chmod(mode, path)
    if LibC.chmod(path, mode) != 0
      raise Errno.new("chmod")
    end
  end

  # :nodoc:
  def chmod(mode)
    if LibC.fchmod(fd, mode) != 0
      raise Errno.new("fchmod")
    end
  end
end

module Frost
  # :nodoc:
  module Commands
    module ShellActions
      TEMPLATES_PATH = __DIR__

      def mkdir(*path_names)
        path_name = File.join(*path_names)

        if Dir.exists?(File.join(app_path, path_name))
          log "exist", path_name, :blue
        else
          log "create", path_name
          Dir.mkdir(File.join(app_path, path_name))
        end
      end

      def touch(*path_names)
        path_name = File.join(*path_names)

        if File.exists?(File.join(app_path, path_name))
          log "exist", path_name, :blue
        else
          log "create", path_name
          File.write(File.join(app_path, path_name), "")
        end
      end

      def chmod(mode, *path_names)
        File.chmod(mode, File.join(app_path, *path_names))
      end

      def write(path, contents)
        if File.exists?(File.join(app_path, path))
          if File.read(File.join(app_path, path)).strip == contents.strip
            log "identical", path, :blue
          else
            log "conflict", path, :red
          end
        else
          log "create", path
          File.write(File.join(app_path, path), contents)
        end
      end

      macro copy(template_name, path)
        %contents = File.read(File.join({{ TEMPLATES_PATH }}, "{{ template_name.id }}.ecr"))
        write {{ path }}, %contents
      end

      macro template(template_name, path)
        %contents = String.build do |__buf__|
          ECR.embed({{ "#{ TEMPLATES_PATH.id }/#{ template_name.id }.ecr" }}, "__buf__")
        end
        write {{ path }}, %contents
      end

      def log(action, detail, color = :green)
        STDOUT << action.rjust(12).colorize(color).bold << "  " << detail << "\n"
        STDOUT.flush
      end
    end

    class ApplicationGenerator
      TEMPLATES_PATH = "#{ __DIR__ }/generators/application"

      include ShellActions
      getter :name, :app_path, :templates_path

      def initialize(@app_path)
        @name = File.basename(app_path)
      end

      def run
        mkdir

        template "Makefile", "Makefile"
        template "main", "#{ name }.cr"
        template "shard", "shard.yml"
        template "gitignore", ".gitignore"

        mkdir "app"
        generate_controllers
        generate_models
        generate_views
        generate_config
        generate_bin
        generate_database
        mkdir "log"
        touch "log", ".keep"
        generate_public

        generate_tests
      end

      def generate_bin
        mkdir "bin"
        template "db", File.join("bin", "db")
        chmod 0o0755, "bin", "db"
      end

      def generate_config
        mkdir "config"
        template "routes", File.join("config", "routes.cr")
        template "environment", File.join("config", "environment.cr")
        template "application", File.join("config", "application.cr")
        template "bootstrap", File.join("config", "bootstrap.cr")
      end

      def generate_controllers
        mkdir "app", "controllers"
        template "application_controller", File.join("app", "controllers", "application_controller.cr")
      end

      def generate_database
        mkdir "db"
        mkdir "db", "migrations"
        touch "db", "migrations", ".keep"
        template "schema", File.join("db", "schema.cr")
        template "database", File.join("config", "database.yml.example")
      end

      def generate_models
        mkdir "app", "models"
        touch "app", "models", ".keep"
      end

      def generate_views
        mkdir "app", "views"
        mkdir "app", "views", "layouts"
        template "application_view", File.join("app", "views", "application_view.cr")
        template "layouts_view", File.join("app", "views", "layouts_view.cr")
        template "layout", File.join("app", "views", "layouts", "application.html.ecr")
      end

      def generate_public
        mkdir "public"
        %w(stylesheets javascripts images).each do |name|
          mkdir "public", name
          touch "public", name, ".keep"
        end
      end

      def generate_tests
        mkdir "test"
        %w(controllers fixtures models).each do |folder|
          mkdir "test", folder
          touch "test", folder, ".keep"
        end
        template "test_helper", File.join("test", "test_helper.cr")
      end

      def self.run(app_path)
        new(app_path).run
      end
    end
  end

  # :nodoc:
  module CLI
    def self.run(args = ARGV)
      case args[0]?
      when "new"
        Commands::ApplicationGenerator.run(args[1])
      else
        STDERR.puts "Usage: frost new <project>"
        STDERR.flush
      end
    end
  end
end

Frost::CLI.run
