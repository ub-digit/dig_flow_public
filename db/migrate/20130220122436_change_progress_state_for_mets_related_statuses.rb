class ChangeProgressStateForMetsRelatedStatuses < ActiveRecord::Migration
  def change
    Status.reset_column_information

    Status.find_by_name("waiting_for_mets_control_begin").update_attribute(:progress_state, "mets") 
    Status.find_by_name("waiting_for_mets_control_end").update_attribute(:progress_state, "mets")
    Status.find_by_name("mets_control_begin").update_attribute(:progress_state, "mets")
    Status.find_by_name("mets_control_end").update_attribute(:progress_state, "mets")
    Status.find_by_name("mets_production_begin").update_attribute(:progress_state, "mets")
    Status.find_by_name("mets_production_end").update_attribute(:progress_state, "mets")
  end
end
