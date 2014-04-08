module Unread
  module Readable
    module Scopes
      def join_read_marks(reader)
        assert_reader(reader)

        joins "LEFT JOIN read_marks ON read_marks.readable_type  = '#{base_class.name}'
                                   AND read_marks.readable_id    = #{table_name}.#{primary_key}
                                   AND read_marks.reader_id      = #{reader.id}
                                   AND read_marks.reader_type    = '#{reader.class.name}'
                                   AND read_marks.timestamp     >= #{table_name}.#{readable_options[:on]}"
      end

      def unread_by(reader)
        result = join_read_marks(reader).
                 where('read_marks.id IS NULL')

        if global_time_stamp = reader.read_mark_global(self).try(:timestamp)
          result = result.where("#{table_name}.#{readable_options[:on]} > '#{global_time_stamp.to_s(:db)}'")
        end

        result
      end

      def with_read_marks_for(reader)
        join_read_marks(reader).select("#{table_name}.*, read_marks.id AS read_mark_id")
      end
    end
  end
end
