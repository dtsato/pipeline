require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

class SampleStage < Pipeline::Stage::Base
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
      
      it "should start with status not_started" do
        Base.new.status.should == :not_started
        Base.new(:status => :something_else).status.should == :not_started
      end
      
      it "should set default name" do
        Base.new.name.should == "Pipeline::Stage::Base"
        SampleStage.new.name.should == "SampleStage"
      end
      
      it "should allow specifying a name on creation" do
        Base.new(:name => "My Name").name.should == "My Name"
        SampleStage.new(:name => "Customized Name").name.should == "Customized Name"
      end
      
      it "should allow completion of stage" do
        stage = Base.new
        stage.complete
        stage.status.should == :completed
      end

      it "should allow completion with custom message" do
        stage = Base.new
        stage.complete("This stage is completed")
        stage.status.should == :completed
        stage.message.should == "This stage is completed"
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
        
      end

    end
  end
end
