require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class FirstStage < Pipeline::Stage::Base
  def perform
    @executed = true
  end
  
  def executed?
    !!@executed
  end
end

class SecondStage < FirstStage; end # Ugly.. just so I don't have to write stub again

class SamplePipeline < Pipeline::Base
  define_stages FirstStage >> SecondStage
end

module Pipeline
  describe Base do

    describe "- configuring" do
      it "should allow accessing stages" do
        SamplePipeline.defined_stages.should == [FirstStage, SecondStage]
      end
    end
    
    describe "- setup" do
      before(:each) do
        @pipeline = SamplePipeline.new
      end
      
      it "should start with status not_started" do
        @pipeline.status.should == :not_started
      end
      
      it "should instantiate stages with status not_started" do
        @pipeline.stages.each { |stage| stage.status.should == :not_started }
      end
      
      it "should validate status" do
        lambda {Base.new(:status => :something_else)}.should raise_error
      end
    end

    describe "- persistence" do
      before(:each) do
        @pipeline = Base.new
      end
      
      it "should persist pipeline instance" do
        @pipeline.id.should be_nil
        lambda {@pipeline.save!}.should_not raise_error
        @pipeline.id.should_not be_nil
      end
      
      it "should allow retrieval by id" do
        @pipeline.save!
        
        retrieved_pipeline = Base.find(@pipeline.id.to_s)
        retrieved_pipeline.should === @pipeline
      end

      it "should persist type as single table inheritance" do
        pipeline = SamplePipeline.new
        pipeline.save!
        
        retrieved_pipeline = Base.find(pipeline.id)
        retrieved_pipeline.should be_an_instance_of(SamplePipeline)
      end
      
      it "should persist pipeline stages" do
        pipeline = SamplePipeline.new
        pipeline.stages.each {|stage| stage.id.should be_nil}
        lambda {pipeline.save!}.should_not raise_error
        pipeline.stages.each {|stage| stage.id.should_not be_nil}
      end
      
      it "should allow retrieval of stages with pipeline instance" do
        pipeline = SamplePipeline.new
        pipeline.save!
        
        retrieved_pipeline = SamplePipeline.find(pipeline.id)
        retrieved_pipeline.stages.should === pipeline.stages
      end

      it "should associate stages with pipeline instance" do
        pipeline = SamplePipeline.new
        pipeline.save!
        
        pipeline.stages.each {|stage| stage.pipeline.should === pipeline}
      end
      
      it "should destroy stages when pipeline instance is destroyed" do
        pipeline = SamplePipeline.new
        pipeline.save!
        
        Pipeline::Stage::Base.count(:conditions => ['pipeline_instance_id = ?', pipeline.id]).should > 0
        
        pipeline.destroy
        Pipeline::Stage::Base.count(:conditions => ['pipeline_instance_id = ?', pipeline.id]).should == 0
      end
    end
    
    describe "- execution (success)" do
      before(:each) do
        @pipeline = SamplePipeline.new
      end

      it "should increment attempts" do
        @pipeline.execute
        @pipeline.attempts.should == 1

        @pipeline.execute
        @pipeline.attempts.should == 2
      end
      
      it "should execute each stage" do
        @pipeline.stages.each { |stage| stage.should_not be_executed }
        @pipeline.execute
        @pipeline.stages.each { |stage| stage.should be_executed }
      end
      
      it "should update pipeline status after all stages finished" do
        @pipeline.execute
        @pipeline.status.should == :completed
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.execute
        @pipeline.reload.status.should == :completed
      end
    end
    
    describe "- execution (in progress)" do
      it "should set status to in_progress" do
        pipeline = SamplePipeline.new
        pipeline.send(:_setup)
        
        pipeline.status.should == :in_progress
        pipeline.reload.status.should == :in_progress
      end
    end
    
    describe "- execution (irrecoverable error)" do
      before(:each) do
        failed_stage = SecondStage.new
        failed_stage.stub!(:perform).and_raise(IrrecoverableError.new)
        SecondStage.stub!(:new).and_return(failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should not re-raise error" do
        lambda {@pipeline.execute}.should_not raise_error(IrrecoverableError)
      end
      
      it "should update status" do
        @pipeline.execute
        @pipeline.status.should == :failed
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.execute
        @pipeline.reload.status.should == :failed
      end
    end
    
    describe "- execution (recoverable error that doesn't require user input)" do
      before(:each) do
        failed_stage = SecondStage.new
        failed_stage.stub!(:perform).and_raise(RecoverableError.new)
        SecondStage.stub!(:new).and_return(failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should re-raise error (so delayed_job retry works)" do
        lambda {@pipeline.execute}.should raise_error(RecoverableError)
      end
      
      it "should update status" do
        lambda {@pipeline.execute}.should raise_error(RecoverableError)
        @pipeline.status.should == :failed
      end
      
      it "should save status" do
        @pipeline.save!
        lambda {@pipeline.execute}.should raise_error(RecoverableError)
        @pipeline.reload.status.should == :failed
      end
    end

    describe "- execution (recoverable error that requires user input)" do
      before(:each) do
        failed_stage = SecondStage.new
        failed_stage.stub!(:perform).and_raise(RecoverableError.new(true))
        SecondStage.stub!(:new).and_return(failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should not re-raise error" do
        lambda {@pipeline.execute}.should_not raise_error(RecoverableError)
      end
      
      it "should update status" do
        @pipeline.execute
        @pipeline.status.should == :paused
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.execute
        @pipeline.reload.status.should == :paused
      end
    end
  end
end
