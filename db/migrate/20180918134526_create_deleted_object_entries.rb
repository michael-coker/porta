class CreateDeletedObjectEntries < ActiveRecord::Migration
  def change
    create_table :deleted_object_entries do |table|
      table.references :owner, polymorphic: true, index: true, type: :bigint
      table.references :object, polymorphic: true, index: true, type: :bigint
      table.text :metadata
      table.datetime :created_at, null: false
    end
  end
end
