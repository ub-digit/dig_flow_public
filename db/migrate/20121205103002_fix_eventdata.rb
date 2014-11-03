class FixEventdata < ActiveRecord::Migration
  def up
    Event.reset_column_information
    Event.find_by_name("change_role").update_attribute(:event_type, "Role")
    Event.find_by_name("change_user").update_attribute(:event_type, "User")
    Event.find_by_name("change_status").update_attribute(:event_type, "Status")
    Event.find_by_name("change_project").update_attribute(:event_type, "Project")
  end

  def down
  end
end
