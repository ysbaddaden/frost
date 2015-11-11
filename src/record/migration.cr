require "./connection"
require "./errors"
require "./migration/schema_migration"

module Trail
  class Record
    class Migration
      def self.find(version)
        migration = all.find { |m| m.version == version }
        raise MigrationError.new("No migration with version #{ version }") unless migration
        migration
      end

      def self.all
        @@all ||= {{ @type.subclasses }}.map(&.new).sort! { |a, b| a.version <=> b.version }
      end

      macro set_version(file)
        def filename
          {{ file.stringify }}
        end

        def version
          {{ file.stringify.split('/').last.split('_').first }}
        end
      end

      # :nodoc;
      def version
        STDERR.puts "ERROR: The #{ self } migration doesn't have a version"
        exit 1
      end

      # :nodoc;
      def execute(action)
        case action.to_s
        when "up"
          unless SchemaMigration.migrated?(version)
            puts "== #{ self.class.name }: migrating"
            start = Time.now
            migrate_up
            SchemaMigration.insert(version)
            puts "== #{ self.class.name }: migrated (#{ (Time.now - start).to_f }s)\n\n"
          end
        when "down"
          if SchemaMigration.migrated?(version)
            puts "== #{ self.class.name }: reverting"
            start = Time.now
            migrate_down
            SchemaMigration.delete(version)
            puts "== #{ self.class.name }: reverted (#{ (Time.now - start).to_f }s)\n\n"
          end
        end
      end

      # :nodoc:
      def migrate_up
      end

      # :nodoc:
      def migrate_down
      end

      macro up(&block)
        def migrate_up
          execute {{ block }}
        end
      end

      macro down(&block)
        def migrate_down
          execute {{ block }}
        end
      end

      private def execute
        Record.connection do |conn|
          conn.transaction { with conn yield }
        end
      end
    end
  end
end
