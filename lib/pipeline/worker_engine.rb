module Pipeline
  class WorkerEngine < Struct.new(:pipeline_instance_id)
    def perform
      pipeline = Base.find(pipeline_instance_id)
      pipeline.execute
    end
  end
end