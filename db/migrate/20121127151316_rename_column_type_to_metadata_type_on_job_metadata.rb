class RenameColumnTypeToMetadataTypeOnJobMetadata < ActiveRecord::Migration
  def up
    rename_column :job_metadata, :type, :metadata_type
  end

  def down
    rename_column :job_metadata, :metadata_type, :type
  end
end
