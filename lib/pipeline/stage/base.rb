module Pipeline
  module Stage # :nodoc:
    # A stage represents one of the steps in a pipeline. Stages can be reused by
    # different pipelines. The behaviour of a stage is determined by subclasses of
    # Pipeline::Stage::Base implementing the method #run:
    #
    #   class PrepareIngredients < Pipeline::Stage::Base
    #     def run
    #       Ingredients.each do |ingredient|
    #         ingredient.wash
    #         ingredient.slice!
    #       end
    #     end
    #   end
    #
    # If a stage need access to its associated pipeline, it can call the association
    # <tt>pipeline</tt>.
    #
    # == Stage Name
    #
    # By default, a stage will have a standard name that corresponds to its fully
    # qualified class name (e.g. Pipeline::Stage::Base or SamplePipeline::SampleStage).
    # You can provide a more descriptive name by calling <tt>default_name</tt>:
    #
    #   class PrepareIngredients < Pipeline::Stage::Base
    #     self.default_name = "Prepare Ingredients for Cooking"
    #   end
    #
    # You can retrieve the name of a stage using the <tt>name</tt> attribute:
    #
    #   stage = PrepareIngredients.new
    #   stage.name # => "Prepare Ingredients for Cooking"
    #
    # == Error Handling
    #
    # In case of failure, a stage can raise special exceptions (RecoverableError or
    # IrrecoverableError) to determine what happens to the pipeline. Please refer to
    # Pipeline::Base for a description of the possible outcomes. Any failure will
    # persist the Exception's message on the <tt>message</tt> attribute and will move
    # the stage to a :failed state.
    #
    # == State Transitions
    # 
    # The following diagram represents the state transitions a stage instance can
    # go through during its life-cycle:
    #
    # :not_started ---> :in_progress ---> :completed
    #                       ^ |
    #                       | v
    #                     :failed
    #
    # [:not_started] The stage was instantiated but not started yet.
    # [:in_progress] After started or retried, the stage remains on this state while
    #                executing.
    # [:completed]   After successfully executing, the stage is completed.
    # [:failed]      If an error occurs, the stage goes into this stage.
    #
    # == Callbacks
    # 
    # You can define custom callbacks to be called before (+before_stage+) and after
    # (+after_stage+) executing a stage. Example:
    #
    #   class PrepareIngredients < Pipeline::Stage::Base
    #     before_stage :wash_ingredients
    #
    #     def run
    #       puts "Slicing..."
    #     end
    #     
    #     protected
    #     def wash_ingredients
    #       puts "Washing..."
    #     end
    #   end
    #
    #   class Cook < Pipeline::Stage::Base
    #     after_stage :serve
    #
    #     def run
    #       puts "Cooking..."
    #     end
    #
    #     protected
    #     def serve
    #       puts "bon appetit!"
    #     end
    #   end
    #
    #   class MakeDinnerPipeline < Pipeline::Base
    #     define_stages PrepareIngredients >> Cook
    #   end
    #
    #   Pipeline.start(MakeDinnerPipeline.new)
    # 
    # Outputs:
    #   Washing...
    #   Slicing...
    #   Cooking...
    #   bon appetit!
    #
    # Callbacks can be defined as a symbol that calls a private/protected method (like the
    # example above), as an inline block, or as a +Callback+ object, as a regular
    # +ActiveRecord+ callback.
    class Base < ActiveRecord::Base
      set_table_name :pipeline_stages
      
      # :not_started ---> :in_progress ---> :completed
      #                       ^ |
      #                       | v
      #                     :failed
      symbol_attr :status
      transactional_attr :status
      private :status=
      
      # Allows access to the associated pipeline
      belongs_to :pipeline, :class_name => "Pipeline::Base", :foreign_key => 'pipeline_instance_id'
            
      class_inheritable_accessor :default_name, :instance_writer => false

      define_callbacks :before_stage, :after_stage

      @@chain = []
      # Method used for chaining stages on a pipeline sequence. Please refer to
      # Pipeline::Base for example usages.
      def self.>>(next_stage)
        @@chain << self
        next_stage
      end
      
      # Method used by Pipeline::Base to construct its chain of stages. Please
      # refer to Pipeline::Base
      def self.build_chain
        chain = @@chain + [self]
        @@chain = []
        chain
      end
      
      # Standard ActiveRecord callback to setup initial name and status
      # when a new stage is instantiated. If you override this callback, make
      # sure to call +super+:
      #
      #   class SampleStage < Pipeline::Stage::Base
      #     def after_initialize
      #       super
      #       self[:special_attribute] ||= "standard value"
      #     end
      #   end
      def after_initialize
        if new_record?
          self[:status] = :not_started
          self.name ||= (default_name || self.class).to_s
        end
      end
      
      # Returns <tt>true</tt> if the stage is in a :completed state, <tt>false</tt>
      # otherwise.
      def completed?
        status == :completed
      end
      
      # Standard method called when executing this stage. Raises   
      # InvalidStatusError if stage is in an invalid state for execution (e.g.
      # already completed, or in progress).
      #
      # <b>NOTE:</b> Do not override this method to determine the behaviour of a
      # stage. This method will be called by the executing pipeline. Please override
      # #run instead.
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
        ensure
          run_callbacks(:after_stage)
        end
      end

      # Abstract method to be implemented by all subclasses that represents the
      # action to be performed by this stage
      def run
        raise "This method must be implemented by any subclass of Pipeline::Stage::Base"
      end
      
      private
      def _setup
        self.attempts += 1
        self.message = nil
        self.status = :in_progress
        run_callbacks(:before_stage)
      end
    end
  end
end