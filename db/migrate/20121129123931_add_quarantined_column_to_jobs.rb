class AddQuarantinedColumnToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :quarantined, :bool, :default => false

    Event.reset_column_information
    Event.create(:name => "quarantine", :event_type => "Quarantine")
    Event.create(:name => "unquarantine", :event_type => "Unquarantine")
  end
end
