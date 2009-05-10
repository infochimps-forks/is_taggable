class IsTaggableMigration < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string   :name,           :limit => MAX_TAG_NAME_LEN,   :default => ''
      t.string   :kind,           :limit => MAX_MODEL_NAME_LEN, :default => ''
    end

    create_table :taggings do |t|
      t.integer  :tag_id
      t.integer  :taggable_id
      t.string   :taggable_type,  :limit => MAX_MODEL_NAME_LEN, :default => ''
    end

    add_index    :tags,        [:name, :kind], :unique => true
    add_index    :tags,        [:kind]   # remove this if you'll only have one or two kinds of tags
    add_index    :taggings,    [:tag_id]
    add_index    :taggings,    [:taggable_id, :taggable_type, :tag_id], :unique => true
  end

  def self.down
    drop_table   :taggings
    drop_table   :tags
  end
end
