class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.text :type
      t.timestamp :deleted_at
      t.integer :created_by
      t.integer :updated_by
      t.integer :deleted_by

      t.timestamps
    end
  end
end
