class AddEventsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :name, :text
    Event.reset_column_information
    Event.create(:name => "change_role", :type => "Role")
    Event.create(:name => "change_user", :type => "User")
    Event.create(:name => "change_status", :type => "Status")
    Event.create(:name => "change_project", :type => "Project")
  end
end
