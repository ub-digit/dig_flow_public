class RenameColumnSortValueToSelectionOrderOnStatuses < ActiveRecord::Migration
  def change
    rename_column :statuses, :sort_value, :selection_order
    
    Status.reset_column_information

    s1 = Status.create(:name => "waiting_for_mets_control_begin", :show => 't')
    s2 = Status.create(:name => "waiting_for_mets_control_end")
    s3 = Status.create(:name => "mets_control_begin", :show => 't')
    s4 = Status.create(:name => "mets_control_end")
    s5 = Status.create(:name => "mets_production_begin", :show => 't')
    s6 = Status.create(:name => "mets_production_end")

    s1.update_attribute(:end_id, s2.id)
    s3.update_attribute(:end_id, s4.id)
    s5.update_attribute(:end_id, s6.id)
  end
end
