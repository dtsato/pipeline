module Pipeline
  class InvalidPipelineError < StandardError; end

  class IrrecoverableError < StandardError; end

  class RecoverableError < StandardError
    def initialize(input_required = false)
      @input_required = input_required
    end

    def input_required?
      @input_required
    end
  end

  extend(ApiMethods)
end