class AddColumnGuessedPageCountToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :guessed_page_count, :integer, :default => 0
  end
end
