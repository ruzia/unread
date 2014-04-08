ActiveRecord::Schema.define(:version => 0) do
  create_table :readers, :primary_key => 'number', :force => true do |t|
    t.string :name
  end

  create_table :other_class_readers, :primary_key => 'number', :force => true do |t|
    t.string :name
  end

  create_table :emails, :primary_key => 'messageid', :force => true do |t|
    t.string :subject
    t.text :content
    t.timestamps
  end

  create_table :read_marks, :force => true do |t|
    t.integer  :readable_id
    t.string   :readable_type, :null => false
    t.integer  :reader_id,       :null => false
    t.string   :reader_type,     :null => false
    t.datetime :timestamp
  end
  add_index :read_marks, [:reader_id, :reader_type, :readable_type, :readable_id], name: 'index_read_marks_on_reader_and_readable'
end
