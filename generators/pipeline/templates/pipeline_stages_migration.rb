class CreatePipelineStages < ActiveRecord::Migration
  def self.up
    create_table :pipeline_stages, :force => true do |t|
      t.references :pipeline_instance             # Pipeline that holds this stage
      t.string     :type                          # For single table inheritance
      t.string     :name                          # Name of the stage
      t.string     :status                        # Current status of the stage
      t.text       :message                       # Message that describes current status
      t.integer    :retry_attempts, :default => 0 # Number of times this stage was executed

      t.timestamps
    end

  end
  
  def self.down
    drop_table :pipeline_stages  
  end
end