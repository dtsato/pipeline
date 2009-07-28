module Pipeline
  module ApiMethods
    def start(pipeline)
      raise InvalidPipelineError.new("Not a valid pipeline") unless pipeline.is_a?(Pipeline::Base)
      pipeline.save!
      Delayed::Job.enqueue(WorkerEngine.new(pipeline.id))
    end
  end
end