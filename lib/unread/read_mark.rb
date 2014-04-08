class ReadMark < ActiveRecord::Base
  belongs_to :readable, :polymorphic => true
  belongs_to :reader, :polymorphic => true
  if ActiveRecord::VERSION::MAJOR < 4
    attr_accessible :readable_id, :reader_id, :readable_type, :reader_type, :timestamp
  end

  validates_presence_of :reader_id, :reader_type, :readable_type

  scope :global, lambda { where(:readable_id => nil) }
  scope :single, lambda { where('readable_id IS NOT NULL') }
  scope :older_than, lambda { |timestamp| where([ 'timestamp < ?', timestamp ]) }

  class_attribute :readable_classes, :reader_classes
end
