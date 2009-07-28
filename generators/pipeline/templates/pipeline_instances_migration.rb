class CreatePipelineInstances < ActiveRecord::Migration
  def self.up
    create_table :pipeline_instances, :force => true do |t|
      t.string :pipeline_definition    # Name of the class that defines the pipeline
      t.string :status                 # Current status of the pipeline

      t.timestamps
    end

  end
  
  def self.down
    drop_table :pipeline_instances  
  end
end