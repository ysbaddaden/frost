module Trail
  # TODO: after_commit & after_rollback callbacks
  # TODO: save!, create!, update!
  class Record
    module Persistence
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
        Record.connection.transaction(requires_new) { yield }
      end

      def save(validate = true)
        if validate && !valid?
          return false
        end

        transaction(requires_new: true) do
          run_save_callbacks do
            if new_record?
              run_create_callbacks { _create }
            else
              run_update_callbacks { _update }
            end
          end
        end
      end

      def update(attributes)
        self.attributes = attributes
        save
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

        attributes = to_hash.delete_if do |k, v|
          k == self.class.primary_key && v == nil
        end

        id = Record.connection.insert(
          self.class.table_name,
          attributes,
          self.class.primary_key,
          self.class.primary_key_type
        )

        if id
          self.id = id
          @new_record = false
          true
        else
          false
        end
      end

      private def _update
        if self.responds_to?(:updated_at)
          self.updated_at = Time.now
        end

        attributes = to_hash.delete_if do |k, _|
          k == self.class.primary_key
        end

        self.class.where({ self.class.primary_key => id }).update_all(attributes)
      end

      def delete
        self.class.delete(id)
        @deleted = true
      end

      def destroy
        run_destroy_callbacks { delete }
      end

      module ClassMethods
        def create(attributes)
          build(attributes).tap { |record| record.save }
        end

        def update(id, attributes)
          find(id).tap { |record| record.update(attributes) }
        end

        def delete(id)
          where({ primary_key => id }).delete_all
        end

        def destroy(id)
          find(id).tap { |record| record.destroy }
        end
      end
    end
  end
end
