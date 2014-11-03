class AddColumnsToStatuses < ActiveRecord::Migration
  def change
    add_column :statuses, :sort_value, :integer
    add_column :statuses, :show, :boolean, :default => false
    add_column :statuses, :progress_state, :text, :default => "started"

    Status.reset_column_information
    Status.find_by_name("waiting_for_digitizing_begin").update_attributes({:show => true, :sort_value => 1, :progress_state => "not_started"})
    Status.find_by_name("digitizing_begin").update_attributes({:show => true, :sort_value => 2})
    Status.find_by_name("waiting_for_post_processing_begin").update_attributes({:show => true, :sort_value => 3})
    Status.find_by_name("post_processing_begin").update_attributes({:show => true, :sort_value => 4})
    Status.find_by_name("post_processing_user_input_begin").update_attributes({:show => true, :sort_value => 5})
    Status.find_by_name("waiting_for_quality_control_begin").update_attributes({:show => true, :sort_value => 6})
    Status.find_by_name("done").update_attributes({:show => true, :sort_value => 7, :progress_state => "done"})
    Status.find_by_name("create_begin").update_attributes({:progress_state => "not_started"})
    Status.find_by_name("create_end").update_attributes({:progress_state => "not_started"})
    Status.find_by_name("deleted").update_attributes({:progress_state => nil})
  end
end
