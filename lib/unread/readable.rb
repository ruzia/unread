module Unread
  module Readable
    module ClassMethods
      def mark_as_read!(target, options)
        reader = options[:for]
        assert_reader(reader)

        if target == :all
          reset_read_marks_for_reader(reader)
        elsif target.is_a?(Array)
          mark_array_as_read(target, reader)
        else
          raise ArgumentError
        end
      end

      def mark_array_as_read(array, reader)
        ReadMark.transaction do
          array.each do |obj|
            raise ArgumentError unless obj.is_a?(self)

            rm = obj.read_marks.where(reader_id: reader.id, reader_type: reader.class.name).first || obj.read_marks.build(reader_id: reader.id, reader_type: reader.class.name)
            rm.timestamp = obj.send(readable_options[:on])
            rm.save!
          end
        end
      end

      # A scope with all items accessable for the given reader
      # It's used in cleanup_read_marks! to support a filtered cleanup
      # Should be overriden if a reader doesn't have access to all items
      # Default: Reader has access to all items and should read them all
      #
      # Example:
      #   def Message.read_scope(reader)
      #     reader.visible_messages
      #   end
      def read_scope(reader)
        self
      end

      def cleanup_read_marks!
        assert_reader_classes

        ReadMark.reader_classes.each do |reader_class|
          reader_class.find_each do |reader|
            ReadMark.transaction do
              if oldest_timestamp = read_scope(reader).unread_by(reader).minimum(readable_options[:on])
                # There are unread items, so update the global read_mark for this reader to the oldest
                # unread item and delete older read_marks
                update_read_marks_for_reader(reader, oldest_timestamp)
              else
                # There is no unread item, so deletes all markers and move global timestamp
                reset_read_marks_for_reader(reader)
              end
            end
          end
        end
      end

      def update_read_marks_for_reader(reader, timestamp)
        # Delete markers OLDER than the given timestamp
        reader.read_marks.where(reader_type: reader.class.name, readable_type: self.base_class.name).single.older_than(timestamp).delete_all

        # Change the global timestamp for this reader
        rm = reader.read_mark_global(self) || reader.read_marks.build(reader_type: reader.class.name, readable_type: self.base_class.name)
        rm.timestamp = timestamp - 1.second
        rm.save!
      end

      def reset_read_marks_for_all
        ReadMark.transaction do
          ReadMark.delete_all :readable_type => self.base_class.name
          ReadMark.reader_classes.each do |reader_class|
            ReadMark.connection.execute <<-EOT
            INSERT INTO read_marks (reader_id, reader_type, readable_type, timestamp)
            SELECT #{reader_class.primary_key}, '#{reader_class.name}', '#{self.base_class.name}', '#{Time.current.to_s(:db)}'
            FROM #{reader_class.table_name}
            EOT
          end
        end
      end

      def reset_read_marks_for_reader(reader)
        assert_reader(reader)

        ReadMark.transaction do
          ReadMark.delete_all :readable_type => self.base_class.name, :reader_id => reader.id, reader_type: reader.class.name
          ReadMark.create!    :readable_type => self.base_class.name, :reader_id => reader.id, reader_type: reader.class.name, :timestamp => Time.current
        end
      end

      def assert_reader(reader)
        assert_reader_classes

        raise ArgumentError, "Class #{reader.class.name} is not registered by acts_as_reader!" unless ReadMark.reader_classes.include? reader.class
        raise ArgumentError, "The given reader has no id!" unless reader.id
      end

      def assert_reader_classes
        raise RuntimeError, 'There is no class using acts_as_reader!' unless ReadMark.reader_classes
      end
    end

    module InstanceMethods
      def unread?(reader)
        if self.respond_to?(:read_mark_id)
          # For use with scope "with_read_marks_for"
          return false if self.read_mark_id

          if global_timestamp = reader.read_mark_global(self.class).try(:timestamp)
            self.send(readable_options[:on]) > global_timestamp
          else
            true
          end
        else
          !!self.class.unread_by(reader).exists?(self) # Rails4 does not return true/false, but nil/count instead.
        end
      end

      def mark_as_read!(options)
        reader = options[:for]
        self.class.assert_reader(reader)

        ReadMark.transaction do
          if unread?(reader)
            rm = read_mark(reader) || read_marks.build(reader_id: reader.id, reader_type: reader.class.name)
            rm.timestamp = self.send(readable_options[:on])
            rm.save!
          end
        end
      end

      def read_mark(reader)
        read_marks.where(reader_id: reader.id, reader_type: reader.class.name).first
      end
    end
  end
end
