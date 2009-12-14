require 'spec/spec_helper'

module Pipeline
  describe ApiMethods do
    class FakePipeline < Pipeline::Base
    end
  
    describe "#start" do
      before(:each) do
        @pipeline = FakePipeline.new
        @pipeline.stub!(:new_record?).and_return(false)
        Delayed::Job.stub!(:enqueue)
      end
      
      it "should only accept instance of Pipeline::Base" do
        lambda {Pipeline.start(@pipeline)}.should_not raise_error
        lambda {Pipeline.start(Object.new)}.should raise_error(InvalidPipelineError, "Invalid pipeline")
      end

      it "should save pipeline instance (for new record)" do
        @pipeline.should_receive(:new_record?).and_return(true)
        @pipeline.should_receive(:save!)
        
        Pipeline.start(@pipeline)
      end

      it "should not save pipeline instance (if already saved)" do
        @pipeline.should_receive(:new_record?).and_return(false)
        @pipeline.should_not_receive(:save!)
        
        Pipeline.start(@pipeline)
      end

      it "should start a job for a pipeline instance" do
        Delayed::Job.should_receive(:enqueue).with(@pipeline)
        
        Pipeline.start(@pipeline)
      end
    
      it "should provide a token for the pipeline instance" do
        @pipeline.stub!(:id).and_return('123')

        token = Pipeline.start(@pipeline)
        token.should == '123'
      end
    end

    describe "#resume" do
      before(:each) do
        @pipeline = Pipeline::Base.new
        @pipeline.stub!(:resume)
        Pipeline::Base.stub!(:find).with('1').and_return(@pipeline)
        Delayed::Job.stub!(:enqueue)
      end
      
      it "should accept a token for a pipeline instance" do
        Pipeline::Base.should_receive(:find).with('1')

        Pipeline.resume('1')
      end

      it "should raise error if trying to resume invalid pipeline" do
        Pipeline::Base.should_receive(:find).
          with('1').
          and_raise(ActiveRecord::RecordNotFound.new)

        lambda {Pipeline.resume('1')}.should raise_error(InvalidPipelineError, "Invalid pipeline")
      end
    
      it "should start a new job for that pipeline instance" do
        Delayed::Job.should_receive(:enqueue).with(@pipeline)
        
        Pipeline.resume('1')
      end
      
      it "should resume pipeline instance" do
        @pipeline.should_receive(:resume)

        Pipeline.resume('1')
      end

    end

    describe "#cancel" do
      before(:each) do
        @pipeline = Pipeline::Base.new
        @pipeline.stub!(:cancel)
        Pipeline::Base.stub!(:find).with('1').and_return(@pipeline)
      end
      
      it "should accept a token for a pipeline instance" do
        Pipeline::Base.should_receive(:find).with('1')
        Pipeline.cancel('1')
      end

      it "should raise error is trying to cancel invalid pipeline" do
        Pipeline::Base.should_receive(:find).
          with('1').
          and_raise(ActiveRecord::RecordNotFound.new)

        lambda {Pipeline.cancel('1')}.should raise_error(InvalidPipelineError, "Invalid pipeline")
      end
    
      it "should cancel pipeline instance" do
        @pipeline.should_receive(:cancel)
        Pipeline.cancel('1')
      end
    end

  end
end