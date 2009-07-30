require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class FirstStage < Pipeline::Stage::Base
  def run
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
        failed_stage = SecondStage.new
        failed_stage.stub!(:run).and_raise(RecoverableError.new("message", true))
        SecondStage.stub!(:new).and_return(failed_stage)
        
        pipeline = SamplePipeline.new
        
        pipeline.perform
        pipeline.attempts.should == 1

        pipeline.perform
        pipeline.attempts.should == 2
      end
      
      it "should perform each stage" do
        @pipeline.stages.each { |stage| stage.should_not be_executed }
        @pipeline.perform
        @pipeline.stages.each { |stage| stage.should be_executed }
      end
      
      it "should update pipeline status after all stages finished" do
        @pipeline.perform
        @pipeline.status.should == :completed
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.perform
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
        failed_stage.stub!(:run).and_raise(IrrecoverableError.new)
        SecondStage.stub!(:new).and_return(failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should not re-raise error" do
        lambda {@pipeline.perform}.should_not raise_error(IrrecoverableError)
      end
      
      it "should update status" do
        @pipeline.perform
        @pipeline.status.should == :failed
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.perform
        @pipeline.reload.status.should == :failed
      end
    end
    
    describe "- execution (recoverable error that doesn't require user input)" do
      before(:each) do
        failed_stage = SecondStage.new
        failed_stage.stub!(:run).and_raise(RecoverableError.new)
        SecondStage.stub!(:new).and_return(failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should re-raise error (so delayed_job retry works)" do
        lambda {@pipeline.perform}.should raise_error(RecoverableError)
      end
      
      it "should update status" do
        lambda {@pipeline.perform}.should raise_error(RecoverableError)
        @pipeline.status.should == :failed
      end
      
      it "should save status" do
        @pipeline.save!
        lambda {@pipeline.perform}.should raise_error(RecoverableError)
        @pipeline.reload.status.should == :failed
      end
    end

    describe "- execution (recoverable error that requires user input)" do
      before(:each) do
        failed_stage = SecondStage.new
        failed_stage.stub!(:run).and_raise(RecoverableError.new('message', true))
        SecondStage.stub!(:new).and_return(failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should not re-raise error" do
        lambda {@pipeline.perform}.should_not raise_error(RecoverableError)
      end
      
      it "should update status" do
        @pipeline.perform
        @pipeline.status.should == :paused
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.perform
        @pipeline.reload.status.should == :paused
      end
    end

    describe "- execution (other errors will pause the pipeline)" do
      before(:each) do
        failed_stage = SecondStage.new
        failed_stage.stub!(:run).and_raise(StandardError.new)
        SecondStage.stub!(:new).and_return(failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should not re-raise error" do
        lambda {@pipeline.perform}.should_not raise_error(StandardError)
      end
      
      it "should update status" do
        @pipeline.perform
        @pipeline.status.should == :paused
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.perform
        @pipeline.reload.status.should == :paused
      end
    end

    describe "- execution (retrying)" do
      before(:each) do
        @passing_stage = FirstStage.new
        FirstStage.stub!(:new).and_return(@passing_stage)
        
        @failed_stage = SecondStage.new
        @failed_stage.stub!(:run).and_raise(RecoverableError.new('message', true))
        SecondStage.stub!(:new).and_return(@failed_stage)
        @pipeline = SamplePipeline.new
      end

      it "should not re-raise error" do
        lambda {@pipeline.perform}.should_not raise_error(RecoverableError)
      end
      
      it "should update status" do
        @pipeline.perform
        @pipeline.status.should == :paused
      end
      
      it "should save status" do
        @pipeline.save!
        @pipeline.perform
        @pipeline.reload.status.should == :paused
      end
      
      it "should skip completed stages" do
        @pipeline.perform
        @passing_stage.attempts.should == 1
        @failed_stage.attempts.should == 1
        
        @pipeline.perform
        @passing_stage.attempts.should == 1
        @failed_stage.attempts.should == 2
      end
    end
    
    describe "- execution (state transitions)" do
      it "should execute if status is :not_started" do
        pipeline = SamplePipeline.new
        
        lambda {pipeline.perform}.should_not raise_error(InvalidStatusError)
      end

      it "should execute if status is :paused (for retrying)" do
        pipeline = SamplePipeline.new
        pipeline.send(:status=, :paused)
        
        lambda {pipeline.perform}.should_not raise_error(InvalidStatusError)
      end
      
      it "should not execute if status is :in_progress" do
        pipeline = SamplePipeline.new
        pipeline.send(:status=, :in_progress)
        
        lambda {pipeline.perform}.should raise_error(InvalidStatusError, "Status is already in progress")
      end

      it "should not execute if status is :completed" do
        pipeline = SamplePipeline.new
        pipeline.send(:status=, :completed)
        
        lambda {pipeline.perform}.should raise_error(InvalidStatusError, "Status is already completed")
      end

      it "should not execute if status is :failed" do
        pipeline = SamplePipeline.new
        pipeline.send(:status=, :failed)
        
        lambda {pipeline.perform}.should raise_error(InvalidStatusError, "Status is already failed")
      end
    end
    
  end
end
