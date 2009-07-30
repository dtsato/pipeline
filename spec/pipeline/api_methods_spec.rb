require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Pipeline
  describe ApiMethods do
    class FakePipeline < Pipeline::Base
    end
  
    describe "#start" do
      before(:each) do
        @pipeline = FakePipeline.new
        @pipeline.stub!(:save!)
        Delayed::Job.stub!(:enqueue)
      end
      
      it "should only accept instance of Pipeline::Base" do
        lambda {Pipeline.start(@pipeline)}.should_not raise_error
        lambda {Pipeline.start(Object.new)}.should raise_error(InvalidPipelineError)
      end

      it "should save pipeline instance" do
        @pipeline.should_receive(:save!)
        
        Pipeline.start(@pipeline)
      end

      it "should start a worker for a pipeline instance" do
        Delayed::Job.should_receive(:enqueue).with(@pipeline)
        
        Pipeline.start(@pipeline)
      end
    
      it "should provide a token for the pipeline instance" do
        @pipeline.stub!(:id).and_return('123')

        token = Pipeline.start(@pipeline)
        token.should == '123'
      end
    end

    describe "#restart" do
      before(:each) do
        @pipeline = Pipeline::Base.new
        Delayed::Job.stub!(:enqueue)
      end
      
      it "should accept a token for a pipeline instance" do
        Pipeline::Base.should_receive(:find).with('1')

        Pipeline.restart('1')
      end
    
      it "should start a new worker for that pipeline instance" do
        Pipeline::Base.stub!(:find).with('1').and_return(@pipeline)
        Delayed::Job.should_receive(:enqueue).with(@pipeline)
        
        Pipeline.restart('1')
      end
      
    end
  end
end