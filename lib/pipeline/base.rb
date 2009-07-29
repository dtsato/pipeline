module Pipeline
  class Base < ActiveRecord::Base
    set_table_name :pipeline_instances
    has_many :stages, :class_name => 'Pipeline::Stage::Base'

    class_inheritable_accessor :defined_stages, :instance_writer => false
    self.defined_stages = []
    
    def self.define_stages(stages)
      self.defined_stages = stages.build_chain
    end

    def after_initialize
      self[:status] = :not_started
      self.class.defined_stages.each do |stage_class|
        stages << stage_class.new
      end
    end
    
    def execute
      stages.each do |s|
        s.execute
        s.complete
      end
      self[:status] = :completed
    end
  end
end