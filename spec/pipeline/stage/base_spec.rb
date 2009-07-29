require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

class SampleStage < Pipeline::Stage::Base
  def perform
    @executed = true
  end
  
  def executed?
    !!@executed
  end
end

class FailedStage < Pipeline::Stage::Base
  def perform
    raise "Can't execute"
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

        it "should allow specifying a name on creation" do
          Base.new(:name => "My Name").name.should == "My Name"
          SampleStage.new(:name => "Customized Name").name.should == "Customized Name"
        end

        it "should start with status not_started" do
          Base.new.status.should == :not_started
          Base.new(:status => :something_else).status.should == :not_started
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
          @stage.execute
          @stage.status.should == :completed
        end
        
        it "should save status" do
          @stage.save!
          @stage.execute
          @stage.reload.status.should == :completed
        end
        
        it "should increment attempts" do
          @stage.execute
          @stage.attempts.should == 1

          @stage.execute
          @stage.attempts.should == 2
        end
        
        it "should call template method #perform" do
          @stage.should_not be_executed
          @stage.execute
          @stage.should be_executed
        end
      end
      
      describe "- execution (failure)" do
        before(:each) do
          @stage = FailedStage.new
        end

        it "should re-raise error" do
          lambda {@stage.execute}.should raise_error
        end
        
        it "should update status" do
          lambda {@stage.execute}.should raise_error
          @stage.status.should == :failed
        end
        
        it "should save status" do
          @stage.save!
          lambda {@stage.execute}.should raise_error
          @stage.reload.status.should == :failed
        end
        
      end

    end
  end
end
