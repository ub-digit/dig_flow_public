class AddColumnsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :marc, :text
    add_column :jobs, :mods, :text
  end
end
