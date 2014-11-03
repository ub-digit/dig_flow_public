class AddColumnMailalertsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mailalerts, :boolean, :default => false
  end
end
