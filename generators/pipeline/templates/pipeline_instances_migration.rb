class CreatePipelineInstances < ActiveRecord::Migration
  def self.up
    create_table :pipeline_instances, :force => true do |t|
      t.string :type        # For single table inheritance
      t.string :status      # Current status of the pipeline

      t.timestamps
    end

  end
  
  def self.down
    drop_table :pipeline_instances  
  end
end