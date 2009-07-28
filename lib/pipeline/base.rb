module Pipeline
  class Base < ActiveRecord::Base
    set_table_name :pipeline_instances
    # has_many :stages, :class_name => 'Pipeline::Stage::Base'

    class_inheritable_accessor :stages, :instance_writer => false
    self.stages = []
    
    class << self
      def add_stages(*stages)
        self.stages += stages
      end
      alias_method :add_stage, :add_stages
    end

    attr_reader :stages
    def after_initialize
      self[:status] = :not_started
      @stages = self.class.stages.map {|s| s.new }
    end
    
    def execute
      @stages.each do |s|
        s.execute
        s.complete
      end
      self[:status] = :completed
    end
  end
end