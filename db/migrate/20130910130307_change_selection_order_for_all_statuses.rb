class ChangeSelectionOrderForAllStatuses < ActiveRecord::Migration
  def change
    Status.reset_column_information

    Status.find_by_name("create_begin").update_attribute(:selection_order, 100)
    Status.find_by_name("create_end").update_attribute(:selection_order, 110)
    Status.find_by_name("waiting_for_digitizing_begin").update_attribute(:selection_order, 120)

    Status.find_by_name("waiting_for_digitizing_end").update_attribute(:selection_order, 200)
    Status.find_by_name("digitizing_begin").update_attribute(:selection_order, 210)

    Status.find_by_name("digitizing_end").update_attribute(:selection_order, 300)
    Status.find_by_name("waiting_for_post_processing_begin").update_attribute(:selection_order, 310)

    Status.find_by_name("waiting_for_post_processing_end").update_attribute(:selection_order, 400)
    Status.find_by_name("post_processing_begin").update_attribute(:selection_order, 410)

    Status.find_by_name("post_processing_user_input_begin").update_attribute(:selection_order, 500)

    Status.find_by_name("post_processing_user_input_end").update_attribute(:selection_order, 600)

    Status.find_by_name("post_processing_end").update_attribute(:selection_order, 700)
    Status.find_by_name("waiting_for_quality_control_begin").update_attribute(:selection_order, 710)

    Status.find_by_name("waiting_for_quality_control_end").update_attribute(:selection_order, 800)
    Status.find_by_name("quality_control_begin").update_attribute(:selection_order, 810)
    Status.find_by_name("quality_control_end").update_attribute(:selection_order, 820)
    Status.find_by_name("waiting_for_mets_control_begin").update_attribute(:selection_order, 830)
    
    Status.find_by_name("waiting_for_mets_control_end").update_attribute(:selection_order, 900)
    Status.find_by_name("mets_control_begin").update_attribute(:selection_order, 910)

    Status.find_by_name("mets_control_end").update_attribute(:selection_order, 1000)
    Status.find_by_name("mets_production_begin").update_attribute(:selection_order, 1010)

    Status.find_by_name("mets_production_end").update_attribute(:selection_order, 1100)
    Status.find_by_name("done").update_attribute(:selection_order, 1110)
  end
end
