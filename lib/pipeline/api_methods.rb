module Pipeline
  # This is the external API for Pipeline. Its methods should be called by client
  # code wanting to manipulate/execute pipelines.
  module ApiMethods
    
    # Used to enqueue a pipeline execution. Raises InvalidPipelineError if the passed
    # in argument is not a subclass of Pipeline::Base. The pipeline will be saved (if
    # not already) and its <tt>id</tt> will be returned.
    def start(pipeline)
      raise InvalidPipelineError.new("Invalid pipeline") unless pipeline.is_a?(Pipeline::Base)
      pipeline.save! if pipeline.new_record?
      Delayed::Job.enqueue(pipeline)
      pipeline.id
    end
    
    # Enqueues execution of a paused pipeline for retrying. Raises InvalidPipelineError
    # if a pipeline can not be found with the provided <tt>id</tt>. Raises
    # InvalidStatusError if pipeline is in an invalid state for resuming (e.g. already
    # cancelled, or completed)
    def resume(id)
      pipeline = Base.find(id)
      pipeline.resume
      Delayed::Job.enqueue(pipeline)
    rescue ActiveRecord::RecordNotFound
      raise InvalidPipelineError.new("Invalid pipeline")
    end
    
    # Cancels execution of a paused pipeline. Raises InvalidPipelineError if a pipeline
    # can not be found with the provided <tt>id</tt>. Raises InvalidStatusError if
    # pipeline is in an invalid state for cancelling (e.g. already cancelled, or
    # completed)
    def cancel(id)
      pipeline = Base.find(id)
      pipeline.cancel
    rescue ActiveRecord::RecordNotFound
      raise InvalidPipelineError.new("Invalid pipeline")
    end
  end
end