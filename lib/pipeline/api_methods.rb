module Pipeline
  module ApiMethods
    def start(pipeline)
      raise InvalidPipelineError.new("Invalid pipeline") unless pipeline.is_a?(Pipeline::Base)
      pipeline.save!
      Delayed::Job.enqueue(pipeline)
      pipeline.id
    end
    
    def resume(id)
      pipeline = Base.find(id)
      raise InvalidStatusError.new(pipeline.status) unless pipeline.ok_to_resume?
      Delayed::Job.enqueue(pipeline)
    rescue ActiveRecord::RecordNotFound
      raise InvalidPipelineError.new("Invalid pipeline")
    end
    
    def cancel(id)
      pipeline = Base.find(id)
      pipeline.cancel
    rescue ActiveRecord::RecordNotFound
      raise InvalidPipelineError.new("Invalid pipeline")
    end
  end
end