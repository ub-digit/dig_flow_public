class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.text :classname

      t.timestamps
    end
  end
end
