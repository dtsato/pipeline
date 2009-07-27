module Pipeline
  module ApiMethods
    def start(pipeline)
      raise InvalidPipelineError.new("Not a valid pipeline") unless pipeline.is_a?(Base)
    end
  end
end