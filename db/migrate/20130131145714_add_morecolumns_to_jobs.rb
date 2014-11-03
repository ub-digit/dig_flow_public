class AddMorecolumnsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :comment, :text
    add_column :jobs, :object_info, :text
  end
end
