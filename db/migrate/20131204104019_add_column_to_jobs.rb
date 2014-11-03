class AddColumnToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :search_title, :text
  end
end
