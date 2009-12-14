require 'spec/spec_helper'

module Pipeline
  describe InvalidPipelineError do
    it "should accept description message when raised" do
      lambda {raise InvalidPipelineError.new, "message"}.should raise_error(InvalidPipelineError, "message")
    end
  end

  describe InvalidStatusError do
    it "should accept status name as symbol" do
      lambda {raise InvalidStatusError.new(:started)}.should raise_error(InvalidStatusError, "Status is already started")
    end

    it "should accept status name as string" do
      lambda {raise InvalidStatusError.new("in progress")}.should raise_error(InvalidStatusError, "Status is already in progress")
    end

    it "should replace underscores with spaces" do
      lambda {raise InvalidStatusError.new(:in_progress)}.should raise_error(InvalidStatusError, "Status is already in progress")
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
      lambda {raise RecoverableError.new("message")}.should raise_error(RecoverableError, "message")
    end
    
    it "might require user input" do
      error = RecoverableError.new("message", true)
      error.should be_input_required
    end

    it "doesn't require user input by default" do
      error = RecoverableError.new
      error.should_not be_input_required
    end
  end
end