class AddCopyrightColumnsToProjectsAndJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :copyright, :integer
    add_column :projects, :copyright, :integer
  end
end
