module Unread
  def self.included(base)
    base.extend Base
  end

  module Base
    def acts_as_reader
      ReadMark.reader_classes ||= []
      ReadMark.reader_classes << self unless ReadMark.reader_classes.include?(self)

      has_many :read_marks, as: :reader, dependent: :delete_all

      after_create do |reader|
        # We assume that a new reader should not be tackled by tons of old messages
        # created BEFORE he signed up.
        # Instead, the new reader starts with zero unread messages
        (ReadMark.readable_classes || []).each do |klass|
          klass.mark_as_read! :all, :for => reader
        end
      end

      include Reader::InstanceMethods
    end

    def acts_as_readable(options={})
      class_attribute :readable_options

      options.reverse_merge!(:on => :updated_at)
      self.readable_options = options

      has_many :read_marks, :as => :readable, :dependent => :delete_all

      ReadMark.readable_classes ||= []
      ReadMark.readable_classes << self unless ReadMark.readable_classes.include?(self)

      include Readable::InstanceMethods
      extend Readable::ClassMethods
      extend Readable::Scopes
    end
  end
end
