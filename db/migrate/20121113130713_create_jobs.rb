class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.text :name
      t.integer :user_id
      t.integer :status_id
      t.integer :catalog_id
      t.integer :project_id
      t.text :title
      t.text :author
      t.text :barcode
      t.timestamp :deleted_at
      t.integer :created_by
      t.integer :updated_by
      t.integer :deleted_by

      t.timestamps
    end
  end
end
