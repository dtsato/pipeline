module Pipeline
  module Stage
    class Base < ActiveRecord::Base
      set_table_name :pipeline_stages
      
      # :not_started ---> :in_progress ---> :completed
      #                                 \-> :failed
      symbol_attr :status
      transactional_attr :status
      private :status=

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
        self.name ||= self.class.to_s
        self[:status] = :not_started if new_record?
      end
      
      def completed?
        status == :completed
      end
      
      def execute
        raise InvalidStatusError.new(status) unless [:not_started, :failed].include?(status)
        _setup
        perform
        self.status = :completed
      rescue => e
        self.message = e.message
        self.status = :failed
        raise e
      end
      
      # Subclass must implement this as part of the contract
      def perform; end
      
      private
      def _setup
        self.attempts += 1
        self.status = :in_progress
      end
    end
  end
end