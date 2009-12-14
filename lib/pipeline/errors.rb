module Pipeline
  # Exception to represents an invalid pipeline. Raised by methods on Pipeline::ApiMethods
  class InvalidPipelineError < StandardError; end
  
  # Exception to represent an invalid state transition. Raised by execution methods on
  # Pipeline::Base and Pipeline::Stage::Base. E.g. trying to transition a :failed
  # pipeline to :in_progress.
  class InvalidStatusError < StandardError
    # The current status of pipeline or stage
    def initialize(status)
      super("Status is already #{status.to_s.gsub(/_/, ' ')}")
    end
  end

  # Exception to represent an irrecoverable error that can be raised by subclasses of
  # Pipeline::Stage::Base that override the method <tt>run</tt>. Please refer to
  # Pipeline::Base for more details about error handling.
  class IrrecoverableError < StandardError; end

  # Exception to represent a recoverable error that can be raised by subclasses of
  # Pipeline::Stage::Base that override the method <tt>run</tt>. Please refer to
  # Pipeline::Base for more details about error handling.
  class RecoverableError < StandardError
    # Instantiates a new instance of RecoverableError.
    # [msg]             Is a description of the error message
    # [input_required]  Is a boolean that determines if the error requires user action
    #                   (<tt>true</tt>, meaning it can not be automatically retried) or
    #                   not (<tt>false</tt>, meaning it can be automatically retried).
    #                   Default is <tt>false</tt>
    def initialize(msg = nil, input_required = false)
      super(msg)
      @input_required = input_required
    end

    # Returns <tt>true</tt> if this error requires user action or <tt>false</tt> otherwise.
    def input_required?
      @input_required
    end
  end
end