require File.join(File.dirname(__FILE__), 'spec_helper')

module Pipeline
  describe ApiMethods do
    class FakePipeline < Pipeline::Base
    end
  
    describe "#start" do
      it "should only accept instance of Pipeline::Base" do
        lambda {Pipeline.start(FakePipeline.new)}.should_not raise_error
        lambda {Pipeline.start(Object.new)}.should raise_error(InvalidPipelineError)
      end
    
      it "should start a worker for a pipeline instance"
    
      it "should provide a token for the pipeline instance"
    end

    describe "#restart" do
      it "should accept a token for a pipeline instance"
    
      it "should start a new worker for that pipeline instance"
    end
  end
end