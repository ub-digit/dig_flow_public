# -*- coding: utf-8 -*-
class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.text :name
      t.timestamp :deleted_at
      t.integer :created_by
      t.integer :updated_by
      t.integer :deleted_by

      t.timestamps
    end

    Role.reset_column_information
    Role.create(:name => "guest")
    Role.create(:name => "operator")
    Role.create(:name => "admin")
  end
end
