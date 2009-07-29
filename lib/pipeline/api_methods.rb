module Pipeline
  module ApiMethods
    def start(pipeline)
      raise InvalidPipelineError.new("Not a valid pipeline") unless pipeline.is_a?(Pipeline::Base)
      pipeline.save!
      Delayed::Job.enqueue(WorkerEngine.new(pipeline.id))
      pipeline.id
    end
    
    def restart(id)
      Delayed::Job.enqueue(WorkerEngine.new(id))
    end
  end
end