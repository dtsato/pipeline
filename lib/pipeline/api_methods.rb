module Pipeline
  module ApiMethods
    def start(pipeline)
      raise InvalidPipelineError.new("Not a valid pipeline") unless pipeline.is_a?(Pipeline::Base)
      pipeline.save!
      Delayed::Job.enqueue(pipeline)
      pipeline.id
    end
    
    def restart(id)
      pipeline = Base.find(id)
      Delayed::Job.enqueue(pipeline)
    end
  end
end