module Pipeline
  module Stage
    class Base < ActiveRecord::Base
      set_table_name :pipeline_stages
      
      def after_initialize
        self[:status] = :not_started
      end
      
      def complete
        self[:status] = :completed
      end
    end
  end
end