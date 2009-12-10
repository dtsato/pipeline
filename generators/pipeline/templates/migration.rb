class CreatePipelineInstancesAndStages < ActiveRecord::Migration
  def self.up
    create_table :pipeline_instances, :force => true do |t|
      t.string  :type                         # For single table inheritance
      t.string  :status                       # Current status of the pipeline
      t.integer :attempts, :default => 0      # Number of times this pipeline was executed
      t.references :external                  # External object, to which this pipeline
                                              # is associated (user-defined)

      t.timestamps
    end

    create_table :pipeline_stages, :force => true do |t|
      t.references :pipeline_instance             # Pipeline that holds this stage
      t.string     :type                          # For single table inheritance
      t.string     :name                          # Name of the stage
      t.string     :status                        # Current status of the stage
      t.text       :message                       # Message that describes current status
      t.integer    :attempts, :default => 0       # Number of times this stage was executed

      t.timestamps
    end
  end
  
  def self.down
    drop_table :pipeline_stages
    drop_table :pipeline_instances
  end
end