class AddInitialUsers < ActiveRecord::Migration
  def up
	role_guest = Role.find_by_name("guest")
	role_admin = Role.find_by_name("admin")
	User.reset_column_information
	User.create(:role => role_guest, :username => "Guest", :name => "guest")
	User.create(:role => role_admin, :username => "admin", :password => "$1$c9c6b4ce$00e46beea797471c7a929694da5bf83d", :name => "Administrator")

  end

  def down
  end
end
