class AddColumnPageCountToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :page_count, :integer
  end
end
