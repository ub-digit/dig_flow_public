class Role < ActiveRecord::Base
  attr_accessible :created_by, :deleted_at, :deleted_by, :name, :updated_by
  has_many :users
end
