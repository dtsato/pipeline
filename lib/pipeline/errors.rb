module Pipeline
  class InvalidPipelineError < StandardError; end
  
  class InvalidStatusError < StandardError
    def initialize(status)
      super("Status is already #{status.to_s.gsub(/_/, ' ')}")
    end
  end

  class IrrecoverableError < StandardError; end

  class RecoverableError < StandardError
    def initialize(msg = nil, input_required = false)
      super(msg)
      @input_required = input_required
    end

    def input_required?
      @input_required
    end
  end

  extend(ApiMethods)
end