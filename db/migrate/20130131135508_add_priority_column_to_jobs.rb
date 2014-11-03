class AddPriorityColumnToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :priority, :integer, :default => 0
  end
end
