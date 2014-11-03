class AddColumnToStatuses < ActiveRecord::Migration
  def change
    add_column :statuses, :return_to_previous, :bool, :default => false
    add_column :statuses, :end_id, :integer

    Status.reset_column_information
    Status.find_by_name("quarantine_begin").destroy
    Status.find_by_name("quarantine_end").destroy
    Status.find_by_name("qualitycheck_begin").update_attribute(:name, "quality_control_begin")
    Status.find_by_name("qualitycheck_end").update_attribute(:name, "quality_control_end")
    Status.find_by_name("postprocess_begin").update_attribute(:name, "post_process_begin")
    Status.find_by_name("postprocess_end").update_attribute(:name, "post_process_end")
    stat = Status.create(:name => "waiting_for_digitizing_end")
    Status.create(:name => "waiting_for_digitizing_begin", :end_id => stat.id)
    stat = Status.create(:name => "waiting_for_post_processing_end")
    Status.create(:name => "waiting_for_post_processing_begin", :end_id => stat.id)
    stat = Status.create(:name => "waiting_for_quality_control_end")
    Status.create(:name => "waiting_for_quality_control_begin", :end_id => stat.id)
    stat = Status.create(:name => "post_process_user_input_end", :return_to_previous => true)
    Status.create(:name => "post_process_user_input_begin", :end_id => stat.id)
    Status.find_by_name("create_begin")
      .update_attribute(:end_id, Status.find_by_name("create_end").id)
    Status.find_by_name("digitizing_begin")
      .update_attribute(:end_id, Status.find_by_name("digitizing_end").id)
    Status.find_by_name("post_process_begin")
      .update_attribute(:end_id, Status.find_by_name("post_process_end").id)
    Status.find_by_name("quality_control_begin")
      .update_attribute(:end_id, Status.find_by_name("quality_control_end").id)
  end
end
