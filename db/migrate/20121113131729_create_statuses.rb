# -*- coding: utf-8 -*-
class CreateStatuses < ActiveRecord::Migration
  def change
    create_table :statuses do |t|
      t.text :name
      t.timestamp :deleted_at
      t.integer :created_by
      t.integer :updated_by
      t.integer :deleted_by

      t.timestamps
    end

    Status.reset_column_information
    Status.create(:name => "create_begin")
    Status.create(:name => "create_end")
    Status.create(:name => "digitizing_begin")
    Status.create(:name => "digitizing_end")
    Status.create(:name => "postprocess_begin")
    Status.create(:name => "postprocess_end")
    Status.create(:name => "qualitycheck_begin")
    Status.create(:name => "qualitycheck_end")
    Status.create(:name => "publish_begin")
    Status.create(:name => "publish_end")
    Status.create(:name => "done")
    Status.create(:name => "deleted")
    Status.create(:name => "quarantine_begin")
    Status.create(:name => "quarantine_end")
  end
end
