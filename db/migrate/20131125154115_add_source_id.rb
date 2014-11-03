class AddSourceId < ActiveRecord::Migration
  def up
    add_column :jobs, :source_id, :integer
  end

  def down
  end
end
