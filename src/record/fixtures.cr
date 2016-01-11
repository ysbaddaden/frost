require "yaml"
require "./errors"

module Frost
  abstract class Record
    class FixtureError < Error
    end

    module TransactionalFixtures
      macro fixtures(path)
        {{ run "./load_fixtures", path }}
      end

      def load_fixtures(klass, fixture_path)
        table_name = klass.table_name
        return if fixture_ids[table_name]?

        file_name = File.basename(fixture_path)
        data = YAML.load(File.read(fixture_path))
        raise FixtureError.new("expected #{file_name} file to be a Hash") unless data.is_a?(Hash)

        Record.connection.execute("TRUNCATE #{ table_name }")
        fixture_ids[table_name] = {} of String => String

        data.each do |name, attributes|
          raise FixtureError.new("expected #{name} of #{file_name} to be a Hash") unless attributes.is_a?(Hash)

          if klass.columns[:created_at]?
            attributes["created_at"] ||= Time.now.to_s
          end
          if klass.columns[:updated_at]?
            attributes["updated_at"] ||= Time.now.to_s
          end

          id = Record.connection.insert(table_name, attributes, klass.primary_key, klass.primary_key_type)
          fixture_ids[table_name][name.to_s] = id.to_s
        end
      end

      def fixture_id(table_name, name)
        if ids = fixture_ids[table_name.to_s]?
          if id = ids[name.to_s]?
            return id
          end
        end
        raise FixtureError.new("Unknown fixture #{name} for #{table_name}")
      end

      private def fixture_ids
        TransactionalFixtures.fixture_ids
      end

      protected def self.fixture_ids
        @@fixture_ids ||= {} of String => Hash(String, String)
      end
    end
  end
end
