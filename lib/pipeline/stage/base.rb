module Pipeline
  module Stage
    class Base < ActiveRecord::Base
      set_table_name :pipeline_stages
      
      # :not_started ---> :in_progress ---> :completed
      #                       ^ |
      #                       | v
      #                     :failed
      symbol_attr :status
      transactional_attr :status
      private :status=

      belongs_to :pipeline, :class_name => "Pipeline::Base", :foreign_key => 'pipeline_instance_id'
      
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
      
      class_inheritable_accessor :default_name, :instance_writer => false
      
      def after_initialize
        if new_record?
          self[:status] = :not_started
          self.name ||= (default_name || self.class).to_s
        end
      end
      
      def completed?
        status == :completed
      end
      
      def perform
        reload unless new_record?
        raise InvalidStatusError.new(status) unless [:not_started, :failed].include?(status)
        begin
          _setup
          run
          self.status = :completed
        rescue Exception => e
          logger.info("Error on stage #{default_name}: #{e.message}")
          logger.info(e.backtrace.join("\n"))
          self.message = e.message
          self.status = :failed
          raise e
        end
      end
      
      # Subclass must implement this as part of the contract
      def run; end
      
      private
      def _setup
        self.attempts += 1
        self.message = nil
        self.status = :in_progress
      end
    end
  end
end