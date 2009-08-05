require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

class SampleStage < Pipeline::Stage::Base
  def run
    @executed = true
  end
  
  def executed?
    !!@executed
  end
end

module Pipeline
  module Stage
    describe Base do

      describe "- chaining" do
        class Step1 < Base; end
        class Step2 < Base; end
        class Step3 < Base; end
        
        it "should start as itself" do
          Step1.build_chain.should == [Step1]
          Step2.build_chain.should == [Step2]
          Step3.build_chain.should == [Step3]
        end

        it "should allow chaining" do
          (Step1 >> Step2).build_chain.should == [Step1, Step2]
          (Step2 >> Step1).build_chain.should == [Step2, Step1]
          (Step1 >> Step2 >> Step3).build_chain.should == [Step1, Step2, Step3]
        end
      end
      
      describe "- setup" do
        it "should set default name" do
          Base.new.name.should == "Pipeline::Stage::Base"
          SampleStage.new.name.should == "SampleStage"
        end
        
        it "should allow overriding name at class level" do
          SampleStage.default_name = "My custom stage name"
          SampleStage.new.name.should == "My custom stage name"

          SampleStage.default_name = :some_symbol
          SampleStage.new.name.should == "some_symbol"
        end

        it "should allow specifying a name on creation" do
          Base.new(:name => "My Name").name.should == "My Name"
          SampleStage.new(:name => "Customized Name").name.should == "Customized Name"
        end

        it "should start with status not_started" do
          Base.new.status.should == :not_started
        end
        
        it "should validate status" do
          lambda {Base.new(:status => :something_else)}.should raise_error
        end
      end
      
      describe "- persistence" do
        before(:each) do
          @stage = SampleStage.new
        end
        
        it "should persist stage" do
          @stage.id.should be_nil
          lambda {@stage.save!}.should_not raise_error
          @stage.id.should_not be_nil
        end
        
        it "should allow retrieval by id" do
          @stage.save!

          s = SampleStage.find(@stage.id)
          s.should === @stage
        end

        it "should persist type as single table inheritance" do
          @stage.save!
          stage = Base.find(@stage.id)
          stage.should be_an_instance_of(SampleStage)
        end
        
      end

      describe "- execution (success)" do
        before(:each) do
          @stage = SampleStage.new
        end
        
        it "should update status after finished" do
          @stage.perform
          @stage.status.should == :completed
          @stage.should be_completed
        end
        
        it "should save status" do
          @stage.save!
          @stage.perform
          @stage.reload.status.should == :completed
          @stage.reload.should be_completed
        end
        
        it "should increment attempts" do
          @stage.stub!(:run).and_raise(StandardError.new)
          lambda {@stage.perform}.should raise_error(StandardError)
          @stage.attempts.should == 1

          lambda {@stage.perform}.should raise_error(StandardError)
          @stage.attempts.should == 2
        end
        
        it "should call template method #run" do
          @stage.should_not be_executed
          @stage.perform
          @stage.should be_executed
        end
      end
      
      describe "- execution (failure)" do
        before(:each) do
          @stage = SampleStage.new
          @stage.stub!(:run).and_raise(StandardError.new)
        end

        it "should re-raise error" do
          lambda {@stage.perform}.should raise_error
        end
        
        it "should update status on irrecoverable error" do
          @stage.should_receive(:run).and_raise(IrrecoverableError.new)
          lambda {@stage.perform}.should raise_error(IrrecoverableError)
          @stage.status.should == :failed
          @stage.reload.status.should == :failed
        end

        it "should update message on irrecoverable error" do
          @stage.should_receive(:run).and_raise(IrrecoverableError.new("message"))
          lambda {@stage.perform}.should raise_error(IrrecoverableError)
          @stage.message.should == "message"
          @stage.reload.message.should == "message"
        end

        it "should update status on recoverable error (not requiring input)" do
          @stage.should_receive(:run).and_raise(RecoverableError.new)
          lambda {@stage.perform}.should raise_error(RecoverableError)
          @stage.status.should == :failed
          @stage.reload.status.should == :failed
        end

        it "should update status on recoverable error (requiring input)" do
          @stage.should_receive(:run).and_raise(RecoverableError.new("message", true))
          lambda {@stage.perform}.should raise_error(RecoverableError)
          @stage.status.should == :failed
          @stage.reload.status.should == :failed
        end

        it "should update message on recoverable error" do
          @stage.should_receive(:run).and_raise(RecoverableError.new("message"))
          lambda {@stage.perform}.should raise_error(RecoverableError)
          @stage.message.should == "message"
          @stage.reload.message.should == "message"
        end

      end
      
      describe "- execution (in progress)" do
        it "should set status to in_progress" do
          stage = SampleStage.new
          stage.send(:_setup)
          
          stage.status.should == :in_progress
          stage.reload.status.should == :in_progress
        end
      end
      
      describe "- execution (state transitions)" do
        it "should execute if status is :not_started" do
          stage = SampleStage.new
          
          lambda {stage.perform}.should_not raise_error(InvalidStatusError)
        end

        it "should execute if status is :failed (for retrying)" do
          stage = SampleStage.new
          stage.send(:status=, :failed)
          
          lambda {stage.perform}.should_not raise_error(InvalidStatusError)
        end
        
        it "should not execute if status is :in_progress" do
          stage = SampleStage.new
          stage.send(:status=, :in_progress)
          
          lambda {stage.perform}.should raise_error(InvalidStatusError, "Status is already in progress")
        end

        it "should not execute if status is :completed" do
          stage = SampleStage.new
          stage.send(:status=, :completed)

          lambda {stage.perform}.should raise_error(InvalidStatusError, "Status is already completed")
        end
      end

    end
  end
end
