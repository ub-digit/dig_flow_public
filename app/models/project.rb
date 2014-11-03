class Project < ActiveRecord::Base
  attr_accessible :created_by, :deleted_at, :deleted_by, :name, :note, :updated_by, :user_id, :copyright
  belongs_to :user
  has_many :jobs

  validates :name, :presence => true
  validates :user_id, :presence => true
  validate :user_validity

  def user_validity
    return if !user
    errors.add(:base, "User must be valid") unless user.role.name=="admin"
  end

  def is_done?
    return false if jobs.blank?
    jobs.each do |job|
      return false if !job.is_done?
    end
    true
  end

  def is_empty?
    return false if !jobs.where( :deleted_at => nil).blank?
    true
  end

  def progress_counters
    pg = jobs.map { |job| job.status.progress_state }.group_by { |state| state.to_sym }
    pg.keys.map { |state| pg[state] = pg[state].count }
    pg
  end

  def progress(state)
    cnt = progress_counters[state] || 0
    total = jobs.count
    return 0 if total == 0
    return 100*(cnt.to_f/total.to_f)
  end
  
  def copyright_value
    copyright
  end
end
