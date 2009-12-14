module Pipeline
  # == Pipeline Stages
  #
  # Each pipeline is composed of sequential stages (see Pipeline::Stage::Base).
  # The stages that will be executed are defined as follows:
  #
  #   class PrepareIngredients < Pipeline::Stage::Base
  #     def run
  #       puts "Slicing..."
  #     end
  #   end
  #
  #   class Cook < Pipeline::Stage::Base
  #     def run
  #       puts "Cooking..."
  #     end
  #   end
  #
  #   class MakeDinnerPipeline < Pipeline::Base
  #     define_stages PrepareIngredients >> Cook
  #   end
  #
  # When this pipeline executes, it will run each stage sequentially, and the output
  # would be:
  #   Slicing...
  #   Cooking...
  #
  # A pipeline can get access to its stages through the <tt>stages</tt> association.
  #
  # == Error Handling
  #
  # There are 3 types of errors that a failed stage can specifically raise:
  #
  # * <b>Recoverable (requires user action)</b>: If a stage raises RecoverableError with
  #   <tt>input_required? == true</tt>, the pipeline gets :paused and can be
  #   resumed or cancelled by calling #resume and #cancel, respectively.
  # 
  # * <b>Recoverable (can be automatically retried)</b>: If a stage raises
  #   RecoverableError with <tt>input_required? == false</tt>, the pipeline goes into
  #   :retry state and will be automatically retried. This is currently achieved by
  #   +delayed_job+'s retry mechanism. Please refer to 
  #   http://github.com/collectiveidea/delayed_job for information about how to
  #   configure the maximum number of retry attempts.
  #
  # * <b>Irrecoverable</b>: If a stage fails with an IrrecoverableError, the pipeline
  #   gets :failed and therefore cannot be resumed or restarted.
  #
  # If a stage fails with any other type of error, you can choose the default behaviour
  # for what happens to the pipeline. By default, the pipeline will pause, so it can be
  # later resumed. This can be overriden by calling +default_failure_mode+ like:
  #
  #  class SamplePipeline < Pipeline::Base
  #    self.default_failure_mode = :cancel
  #  end
  # 
  # You can always go back to the default mode by calling:
  #   self.default_failure_mode = :pause
  #
  # == State Transitions
  # 
  # The following diagram represents the state transitions a pipeline instance can
  # go through during its life-cycle:
  #
  # :not_started ---> :in_progress ---> :completed / :failed
  #                       ^ |
  #                       | v
  #                 :paused / :retry
  #
  # [:not_started] The pipeline was instantiated but not started yet.
  # [:in_progress] After started or resumed, the pipeline remains on this state while
  #                the stages are running.
  # [:paused]      If a stage fails with a recoverable error that requires user action,
  #                the pipeline gets paused.
  # [:retry]       If a stage fails with a recoverable error that can be automatically
  #                retried, the pipeline goes into this stage.
  # [:completed]   After successfully running all stages, the pipeline is completed.
  # [:failed]      If a stage fails with an unrecoverable error, or if the pipeline is
  #                cancelled, it goes into this stage.
  #
  # == Referencing External Objects
  #
  # The execution of a pipeline will usually be associated to an external entity
  # (e.g. a +User+ if the stages represent an internal user registration process, or a
  # +Recipe+ in the examples of this page). To be able to reference the associated object
  # from the stages, Pipeline::Base has an attribute <tt>external_id</tt> that can be
  # used on a custom association to any external entity. Example:
  #
  #   class MakeDinnerPipeline < Pipeline::Base
  #     define_stages PrepareIngredients >> Cook
  #     belongs_to :recipe, :foreign_key => 'external_id'
  #   end
  #
  # A Stage can reference this object as such:
  #
  #   class Cook < Pipeline::Stage::Base
  #     def run
  #       puts "Cooking a delicious #{pipeline.recipe.name}"
  #     end
  #   end
  #
  # == Callbacks
  # 
  # You can define custom callbacks to be called before (+before_pipeline+) and after
  # (+after_pipeline+) executing a pipeline. Example:
  #
  #   class PrepareIngredients < Pipeline::Stage::Base
  #     def run
  #       puts "Slicing..."
  #     end
  #   end
  #
  #   class Cook < Pipeline::Stage::Base
  #     def run
  #       puts "Cooking..."
  #     end
  #   end
  #
  #   class MakeDinnerPipeline < Pipeline::Base
  #     define_stages PrepareIngredients >> Cook
  #
  #     before_pipeline :wash_hands
  #     after_pipeline :serve_dinner
  #     
  #     private
  #     def wash_hands
  #       puts "Washing hands before we start..."
  #     end
  #
  #     def serve_dinner
  #       puts "bon appetit!"
  #     end
  #   end
  # 
  #   Pipeline.start(MakeDinnerPipeline.new)
  #
  # Outputs:
  #   Washing hands before we start...
  #   Slicing...
  #   Cooking...
  #   bon appetit!
  #
  # Callbacks can be defined as a symbol that calls a private/protected method (like the
  # example above), as an inline block, or as a +Callback+ object, as a regular
  # +ActiveRecord+ callback.
  class Base < ActiveRecord::Base
    set_table_name :pipeline_instances
    
    # :not_started ---> :in_progress ---> :completed / :failed
    #                       ^ |
    #                       | v
    #                 :paused / :retry
    symbol_attr :status
    transactional_attr :status
    private :status=

    # Allows access to the associated stages
    has_many :stages,
      :class_name => 'Pipeline::Stage::Base',
      :foreign_key => 'pipeline_instance_id',
      :dependent => :destroy

    class_inheritable_accessor :defined_stages, :instance_writer => false
    self.defined_stages = []

    class_inheritable_accessor :failure_mode, :instance_writer => false
    self.failure_mode = :pause
    
    define_callbacks :before_pipeline, :after_pipeline
    
    # Defines the stages of this pipeline. Please refer to section
    # <em>"Pipeline Stages"</em> above
    def self.define_stages(stages)
      self.defined_stages = stages.build_chain
    end

    # Sets the behaviour of this pipeline when a failure occurs. Accepted symbols are:
    #
    # [:pause]  Pauses the pipeline on failure (default)
    # [:cancel] Fails the pipeline on failure
    def self.default_failure_mode=(mode)
      new_mode = [:pause, :cancel].include?(mode) ? mode : :pause
      self.failure_mode = new_mode
    end

    # Standard ActiveRecord callback to setup initial stages and status
    # when a new pipeline is instantiated. If you override this callback, make
    # sure to call +super+:
    #
    #   class SamplePipeline < Pipeline::Base
    #     def after_initialize
    #       super
    #       self[:special_attribute] ||= "standard value"
    #     end
    #   end
    def after_initialize
      if new_record?
        self[:status] = :not_started
        self.class.defined_stages.each do |stage_class|
          stages << stage_class.new(:pipeline => self)
        end
      end
    end
    
    # Standard +delayed_job+ method called when executing this pipeline. Raises   
    # InvalidStatusError if pipeline is in an invalid state for execution (e.g.
    # already cancelled, or completed).
    #
    # This method will be called by +delayed_job+
    # if this object is enqueued for asynchronous execution. However, you could
    # call this method and execute the pipeline synchronously, without relying on
    # +delayed_job+. Auto-retry would not work in this case, though.
    def perform
      _check_valid_status
      begin
        _setup
        stages.each do |stage|
          stage.perform unless stage.completed?
        end
        _complete_with_status(:completed)
      rescue IrrecoverableError
        _complete_with_status(:failed)
      rescue RecoverableError => e
        if e.input_required?
          _complete_with_status(:paused)
        else
          _complete_with_status(:retry)
          raise e
        end
      rescue Exception
        _complete_with_status(failure_mode == :cancel ? :failed : :paused)
      end
    end
    
    # Attempts to cancel this pipeline. Raises InvalidStatusError if pipeline is in
    # an invalid state for cancelling (e.g. already cancelled, or completed)
    def cancel
      _check_valid_status
      _complete_with_status(:failed)
    end
    
    # Attempts to resume this pipeline. Raises InvalidStatusError if pipeline is in
    # an invalid state for resuming (e.g. already cancelled, or completed)
    def resume
      _check_valid_status
    end
    
    private
    def ok_to_resume?
      [:not_started, :paused, :retry].include?(status)
    end

    def _check_valid_status
      reload unless new_record?
      raise InvalidStatusError.new(status) unless ok_to_resume?
    end
    
    def _setup
      self.attempts += 1
      self.status = :in_progress
      run_callbacks(:before_pipeline)
    end
    
    def _complete_with_status(status)
      self.status = status
      run_callbacks(:after_pipeline)
    end
  end
end