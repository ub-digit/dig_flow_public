class JobMetadatum < ActiveRecord::Base
  default_scope where( :deleted_at => nil ) #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  attr_accessible :created_by, :deleted_at, :deleted_by, :job_id, :key, :metadata_type, :updated_by, :value
  belongs_to :job

  validates :job_id, :presence => true
  validates :key, :presence => true
  validates :value, :presence => true
  validates :metadata_type, :presence => true
  validate  :job_validity
  validates :value, :format => { :with => /\A(true|false)\Z/i }, :if => :type_is_boolean?
  validates :value, :format => { :with => /\A\d+\Z/i }, :if => :type_is_integer?
  before_validation :downcase_value_if_boolean

  def job_validity
    errors.add(:base, "Job must be valid") unless Job.find_by_id(job_id)
  end

  def type_is_boolean?
    metadata_type=="boolean"
  end

  def type_is_integer?
    metadata_type=="integer"
  end

  def downcase_value_if_boolean
    self.value = self.value.downcase if self.value && type_is_boolean?
  end

end
