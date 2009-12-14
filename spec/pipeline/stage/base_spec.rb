require 'spec/spec_helper'

module Pipeline
  module Stage
    describe Base do

      context "- chaining" do
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
      
      context "- setup" do
        it "should set default name" do
          Base.new.name.should == "Pipeline::Stage::Base"
          ::SampleStage.new.name.should == "SampleStage"
        end
        
        it "should allow overriding name at class level" do
          StubStage.default_name = "My custom stage name"
          StubStage.new.name.should == "My custom stage name"

          StubStage.default_name = :some_symbol
          StubStage.new.name.should == "some_symbol"
        end

        it "should allow specifying a name on creation" do
          Base.new(:name => "My Name").name.should == "My Name"
          StubStage.new(:name => "Customized Name").name.should == "Customized Name"
        end

        it "should start with status not_started" do
          Base.new.status.should == :not_started
        end
        
        it "should validate status" do
          lambda {Base.new(:status => :something_else)}.should raise_error
        end        

        it "should raise error if subclass doesn't implement #run" do
          lambda {Base.new.run}.should raise_error("This method must be implemented by any subclass of Pipeline::Stage::Base")
        end
      end
      
      context "- persistence" do
        before(:each) do
          @stage = StubStage.new
        end
        
        it "should persist stage" do
          @stage.should be_new_record
          lambda {@stage.save!}.should_not raise_error
          @stage.should_not be_new_record
        end
        
        it "should allow retrieval by id" do
          @stage.save!

          s = StubStage.find(@stage.id)
          s.should === @stage
          
          lambda {Base.find('invalid_id')}.should raise_error(ActiveRecord::RecordNotFound)          
        end

        it "should persist type as single table inheritance" do
          @stage.save!
          stage = Base.find(@stage.id)
          stage.should be_an_instance_of(StubStage)
        end
        
        it "should belong to pipeline instance" do
          pipeline = Pipeline::Base.create
          @stage.pipeline = pipeline
          @stage.save!
          
          Base.find(@stage.id).pipeline.should == pipeline
        end
        
      end

      context "- execution (success)" do
        before(:each) do
          @stage = StubStage.new
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
          @stage.attempts.should == 0
          @stage.perform
          @stage.attempts.should == 1
        end
        
        it "should call template method #run" do
          @stage.should_not be_executed
          @stage.perform
          @stage.should be_executed
        end
                
      end
      
      context "- execution (failure)" do
        it "should re-raise error" do
          stage = FailedStage.new
          lambda {stage.perform}.should raise_error
        end
        
        it "should update status on irrecoverable error" do
          stage = IrrecoverableStage.new
          lambda {stage.perform}.should raise_error(IrrecoverableError)
          stage.status.should == :failed
          stage.reload.status.should == :failed
        end

        it "should update message on irrecoverable error" do
          stage = IrrecoverableStage.new
          lambda {stage.perform}.should raise_error(IrrecoverableError)
          stage.message.should == "message"
          stage.reload.message.should == "message"
        end

        it "should update status on recoverable error (not requiring input)" do
          stage = RecoverableStage.new
          lambda {stage.perform}.should raise_error(RecoverableError)
          stage.status.should == :failed
          stage.reload.status.should == :failed
        end

        it "should update status on recoverable error (requiring input)" do
          stage = RecoverableInputRequiredStage.new
          lambda {stage.perform}.should raise_error(RecoverableError)
          stage.status.should == :failed
          stage.reload.status.should == :failed
        end

        it "should update message on recoverable error" do
          stage = RecoverableStage.new
          lambda {stage.perform}.should raise_error(RecoverableError)
          stage.message.should == "message"
          stage.reload.message.should == "message"
        end
        
        it "should capture generic Exception" do
          stage = GenericErrorStage.new
          lambda {stage.perform}.should raise_error(Exception)
          stage.status.should == :failed
          stage.reload.status.should == :failed
        end
        
        it "should log exception message and backtrace" do
          class StageFailWithDetails < StubStage
            self.default_name = "Fail With Details"
            
            def run
              super
              error = StandardError.new("error message")
              error.set_backtrace(['a', 'b', 'c'])
              raise error
            end
          end
          stage = StageFailWithDetails.new

          stage.logger.should_receive(:info).with("Error on stage Fail With Details: error message")
          stage.logger.should_receive(:info).with("a\nb\nc")
          lambda {stage.perform}.should raise_error
        end

        it "should refresh object (in case it was cancelled after job was scheduled)" do
          # Gets failed on the first time
          stage = RecoverableStage.create!
          lambda {stage.perform}.should raise_error(RecoverableError)

          # Status gets updated to completed on the database (not on the current instance)
          same_stage = StubStage.find(stage.id)
          same_stage.update_attribute(:status, :completed)

          # Retrying should fail because stage is now completed
          lambda {stage.perform}.should raise_error(InvalidStatusError, "Status is already completed")
        end

      end
      
      context "- execution (in progress)" do
        it "should set status to in_progress" do
          stage = StubStage.new
          stage.send(:_setup)
          
          stage.status.should == :in_progress
          stage.reload.status.should == :in_progress
        end

        it "should clear message when restarting" do
          stage = StubStage.new(:message => 'some message')
          stage.send(:_setup)
          
          stage.message.should be_nil
          stage.reload.message.should be_nil
        end
      end
      
      context "- execution (state transitions)" do
        before(:each) do
          @stage = StubStage.new
        end

        it "should execute if status is :not_started" do
          lambda {@stage.perform}.should_not raise_error(InvalidStatusError)
        end

        it "should execute if status is :failed (for retrying)" do
          @stage.update_attribute(:status, :failed)
          
          lambda {@stage.perform}.should_not raise_error(InvalidStatusError)
        end
        
        it "should not execute if status is :in_progress" do
          @stage.update_attribute(:status, :in_progress)
          
          lambda {@stage.perform}.should raise_error(InvalidStatusError, "Status is already in progress")
        end

        it "should not execute if status is :completed" do
          @stage.update_attribute(:status, :completed)

          lambda {@stage.perform}.should raise_error(InvalidStatusError, "Status is already completed")
        end
      end

      context "- callbacks" do
        before(:each) do
          @stage = ::SampleStage.new
        end

        it "should allow callback before running the stage" do
          @stage.should_receive(:before_stage_callback).once
          @stage.perform
        end

        it "should allow callback after running the stage on success" do
          @stage.should_receive(:after_stage_callback).once
          @stage.perform
        end

        it "should allow callback after running the stage on failure" do
          @stage.stub!(:run).and_raise("error")
          @stage.should_receive(:after_stage_callback).once
          lambda {@stage.perform}.should raise_error
        end
      end
    end
  end
end
