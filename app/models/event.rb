class Event < ActiveRecord::Base
  attr_accessible :name, :created_by, :deleted_at, :deleted_by, :event_type, :updated_by
  has_many :activities


  def object(event_object_id)
    begin
      Kernel.const_get(event_type).send(:find_by_id, event_object_id)
    rescue NameError
      return nil
    end
  end

  def run_event(entity_object, new_id, note = nil)
    from_object = entity_object.send(event_type.tableize.singularize)
    entity_object.send("#{event_type.tableize.singularize}_id=", new_id)
    if entity_object.save
      tmp = activities.create(:entity_id => entity_object.id, :entity_type => entity_object.class.to_s,
                 :to_id => new_id, :from_id => from_object.id, :note => note)
    end
  end
end
