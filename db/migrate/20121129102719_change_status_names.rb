class ChangeStatusNames < ActiveRecord::Migration
  def up
    Status.find_by_name("post_process_begin").update_attribute(:name, "post_processing_begin")
    Status.find_by_name("post_process_end").update_attribute(:name, "post_processing_end")
    Status.find_by_name("post_process_user_input_begin")
      .update_attribute(:name, "post_processing_user_input_begin")
    Status.find_by_name("post_process_user_input_end")
      .update_attribute(:name, "post_processing_user_input_end")
  end

  def down
  end
end
