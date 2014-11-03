class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.integer :entity_id
      t.text :entity_type
      t.integer :event_id
      t.integer :from_id
      t.integer :to_id
      t.text :note
      t.timestamp :deleted_at
      t.integer :created_by
      t.integer :updated_by
      t.integer :deleted_by

      t.timestamps
    end
  end
end
