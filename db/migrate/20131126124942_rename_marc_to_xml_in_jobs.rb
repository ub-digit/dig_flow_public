class RenameMarcToXmlInJobs < ActiveRecord::Migration
  def up
    rename_column :jobs, :marc, :xml
  end

  def down
    rename_column :jobs, :xml, :marc
  end
end
