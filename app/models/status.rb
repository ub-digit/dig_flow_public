class Status < ActiveRecord::Base
  attr_accessible :created_by, :deleted_at, :deleted_by, :name, :updated_by, :end_id, :return_to_previous, :show, :selection_order, :progress_state

  belongs_to :end_status, :foreign_key => :end_id, :class_name => "Status"
  has_one :begin_status, :foreign_key => :end_id, :class_name => "Status"
end
