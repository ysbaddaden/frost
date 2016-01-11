module Frost
  abstract class Record
    module Persistence
      # TODO: after_commit & after_rollback callbacks
      # TODO: freeze attributes when record is deleted or destroyed

      macro included
        extend ClassMethods
        define_model_callbacks :save, :create, :update, :destroy
      end

      def new_record?
        @new_record != false
      end

      # :nodoc:
      def new_record=(@new_record)
      end

      def persisted?
        !new_record?
      end

      def deleted?
        @deleted == true
      end

      def transaction(requires_new = false)
        Record.connection do |conn|
          conn.transaction(requires_new) { yield }
        end
      end

      def save(validate = true)
        return false if validate && !run_validation
        create_or_update
      end

      def save!(validate = true)
        raise RecordInvalid.new(self) if validate && !run_validation
        create_or_update || raise RecordNotSaved.new(self)
      end

      private def run_validation
        @validating = true
        success = valid?

        if success && self.responds_to?(:handle_validate_dependencies)
          self.handle_validate_dependencies
          return errors.empty?
        end

        success
      ensure
        @validating = false
      end

      def update(attributes)
        self.attributes = attributes
        save
      end

      def update!(attributes)
        self.attributes = attributes
        save!
      end

      private def create_or_update
        @saving = true

        transaction(requires_new: true) do
          run_save_callbacks do
            if new_record?
              run_create_callbacks { _create }
            else
              run_update_callbacks { _update }
            end
          end
        end
      ensure
        @saving = nil
      end

      private def _create
        Time.now.tap do |time|
          if self.responds_to?(:created_at)
            self.created_at ||= time
          end
          if self.responds_to?(:updated_at)
            self.updated_at ||= time
          end
        end

        handle_save_dependencies do
          attributes = to_hash.delete_if { |k, v| k == self.class.primary_key && v == nil }

          if id = Record.connection.insert(self.class.table_name, attributes, self.class.primary_key, self.class.primary_key_type)
            self.id = id
            @new_record = false
          end

          !! id
        end
      end

      private def _update
        if self.responds_to?(:updated_at)
          self.updated_at = Time.now
        end

        handle_save_dependencies do
          attributes = to_hash.delete_if { |k, _| k == self.class.primary_key }
          self.class.where({ self.class.primary_key => id }).update_all(attributes)
        end
      end

      protected def _validating?
        !!@validating
      end

      protected def _saving?
        !!@saving
      end

      def delete
        self.class.delete(id)
        @deleted = true
      end

      def destroy
        transaction(requires_new: true) do
          begin
            success = run_destroy_callbacks { delete }

            if success && self.responds_to?(:handle_delete_dependencies)
              self.handle_delete_dependencies
            end

            success
          rescue ex
            @deleted = false
            raise ex
          end
        end
      end

      def destroy!
        destroy || raise RecordNotDestroyed.new(self)
      end

      module ClassMethods
        def create(attributes)
          build(attributes).tap { |record| record.save }
        end

        def create!(attributes)
          build(attributes).tap { |record| record.save! }
        end

        def update(id, attributes)
          find(id).tap { |record| record.update(attributes) }
        end

        def update!(id, attributes)
          find(id).tap { |record| record.update!(attributes) }
        end

        def delete(id)
          where({ primary_key => id }).delete_all
        end

        def destroy(id)
          find(id).tap { |record| record.destroy }
        end

        def destroy!(id)
          find(id).tap { |record| record.destroy! }
        end
      end
    end
  end
end
