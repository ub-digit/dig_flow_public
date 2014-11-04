class AddSources < ActiveRecord::Migration
  def up
	Source.create(:classname => "Libris")
  end

  def down
  end
end
