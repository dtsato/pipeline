require File.dirname(__FILE__) + '/../spec_helper'

module Pipeline
  describe InvalidPipelineError do
    it "should accept description message when raised" do
      lambda {raise InvalidPipelineError.new, "message"}.should raise_error(InvalidPipelineError, "message")
    end
  end

  describe IrrecoverableError do
    it "should accept description message when raised" do
      lambda {raise IrrecoverableError.new, "message"}.should raise_error(IrrecoverableError, "message")
    end
  end

  describe RecoverableError do
    it "should accept description message when raised" do
      lambda {raise RecoverableError.new, "message"}.should raise_error(RecoverableError, "message")
    end
    
    it "might require user input" do
      error = RecoverableError.new(true)
      error.should be_input_required
    end

    it "doesn't require user input by default" do
      error = RecoverableError.new
      error.should_not be_input_required
    end
  end
end