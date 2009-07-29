module Pipeline
  module Stage
    class Base < ActiveRecord::Base
      set_table_name :pipeline_stages
      belongs_to :pipeline, :class_name => "Pipeline::Base"
      
      @@chain = []
      def self.>>(next_stage)
        @@chain << self
        next_stage
      end
      
      def self.build_chain
        chain = @@chain + [self]
        @@chain = []
        chain
      end
      
      def after_initialize
        self[:name] ||= self.class.to_s
        self[:status] = :not_started
      end
      
      def complete(message = nil)
        self[:status] = :completed
        self[:message] = message.to_s if message
      end
      
      # Subclass must implement this as part of the contract
      def execute; end
    end
  end
end