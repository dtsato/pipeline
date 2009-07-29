module Pipeline
  class Base < ActiveRecord::Base
    set_table_name :pipeline_instances
    symbol_attr :status
    transactional_attr :status
    private :status=

    has_many :stages, :class_name => 'Pipeline::Stage::Base', :foreign_key => 'pipeline_instance_id', :dependent => :destroy

    class_inheritable_accessor :defined_stages, :instance_writer => false
    self.defined_stages = []
    
    def self.define_stages(stages)
      self.defined_stages = stages.build_chain
    end

    def after_initialize
      self[:status] = :not_started if new_record?
      if new_record?
        self.class.defined_stages.each do |stage_class|
          stages << stage_class.new(:pipeline => self)
        end
      end
    end
    
    def execute
      self.attempts += 1
      stages.each do |stage|
        stage.execute
      end
      self.status = :completed
      save!
    end
  end
end