class CreateJobMetadata < ActiveRecord::Migration
  def change
    create_table :job_metadata do |t|
      t.integer :job_id
      t.text :key
      t.text :value
      t.text :type
      t.timestamp :deleted_at
      t.integer :created_by
      t.integer :updated_by
      t.integer :deleted_by

      t.timestamps
    end
  end
end
