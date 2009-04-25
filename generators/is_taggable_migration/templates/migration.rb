class IsTaggableMigration < ActiveRecord::Migration
  MAX_STR_LEN_TAG_NAME   = 100
  MAX_STR_LEN_MODEL_NAME = 20
  def self.up
    create_table :tags do |t|
      t.string :name, :default => '', :limit => MAX_STR_LEN_TAG_NAME
      t.string :kind, :default => '', :limit => MAX_STR_LEN_MODEL_NAME
    end

    create_table :taggings do |t|
      t.integer :tag_id
      t.string  :taggable_type, :default => '', :limit => MAX_STR_LEN_MODEL_NAME
      t.integer :taggable_id
    end

    add_index :tags,     [:name, :kind], :unique => true
    add_index :taggings, [:tag_id]
    add_index :taggings, [:taggable_id, :taggable_type, :tag_id], :unique => true
  end

  def self.down
    drop_table :taggings
    drop_table :tags
  end
end
