class UnreadMigration < ActiveRecord::Migration
  def self.up
    create_table :read_marks,    :force => true do |t|
      t.integer  :readable_id
      t.string   :readable_type, :null => false, :limit => 20
      t.integer  :reader_id,     :null => false
      t.string   :reader_type,   :null => false, :limit => 20
      t.datetime :timestamp
    end

    add_index :read_marks, [:reader_id, :reader_type, :readable_type, :readable_id], name: 'index_read_marks_on_reader_and_readable'
  end

  def self.down
    drop_table :read_marks
  end
end
