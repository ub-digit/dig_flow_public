class AddInitialUsers < ActiveRecord::Migration
  def up
	User.reset_column_information
	User.create(:role_id => 1, :username => "Guest", :name => "guest")
	User.create(:role_id => 3, :username => "admin", :password => "$1$c9c6b4ce$00e46beea797471c7a929694da5bf83d", :name => "Administrator")

  end

  def down
  end
end
