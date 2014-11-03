class Activity < ActiveRecord::Base
  attr_accessible :created_by, :deleted_at, :deleted_by, :entity_id, :entity_type, :event_id, :from_id, :note, :to_id, :updated_by
  belongs_to :event

  validates :entity_type, :presence => true
  validates :entity_id, :presence => true
  validates :from_id, :presence => true
  validates :to_id, :presence => true
  validates :event_id, :presence => true
  validate :entity_type_validity
  validate :entity_id_validity
  validate :event_id_validity
  validate :from_id_validity
  validate :to_id_validity


  def object
    begin
      Kernel.const_get(entity_type).send(:find_by_id, entity_id)
    rescue NameError
      return nil
    end
  end

  def from_object
    begin
      Kernel.const_get(event.event_type).send(:find_by_id, from_id)
    rescue NameError
      return nil
    end
  end

  def to_object
    begin
      Kernel.const_get(event.event_type).send(:find_by_id, to_id)
    rescue NameError
      return nil
    end
  end

  def entity_id_validity
    return if !entity_type
    errors.add(:base, "Entity_id must be valid") unless object
  end

  def from_id_validity
    return if !event
    errors.add(:base, "From_id must be valid") unless event.object(from_id)
  end

  def to_id_validity
    return if !event
    errors.add(:base, "To_id must be valid") unless event.object(to_id)
  end

  def entity_type_validity
    return if !entity_type
    begin
      type = Kernel.const_get(entity_type)
    rescue NameError
      errors.add(:base, "Entity_type must be valid")
    end
  end

  def event_id_validity
    errors.add(:base, "Event_id must be valid") unless Event.find_by_id(event_id)
  end
end
