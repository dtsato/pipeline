require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Pipeline
  describe Base do
    class FirstStage < Pipeline::Stage::Base
      def initialize
        @executed = false
        super
      end
      
      def execute
        @executed = true
      end
      
      def executed?
        @executed
      end
    end
    
    class SecondStage < FirstStage; end # Ugly.. just so I don't have to write stub again
    
    class SamplePipeline < Pipeline::Base
      add_stage FirstStage
      add_stage SecondStage
    end

    class AnotherSamplePipeline < Pipeline::Base
      add_stages FirstStage, SecondStage
    end
    
    describe "- configuring" do
      it "should allow accessing stages" do
        SamplePipeline.stages.should == [FirstStage, SecondStage]
      end
    
      it "should allow adding stages" do
        AnotherSamplePipeline.stages.should == [FirstStage, SecondStage]
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
        
        p = Base.find(@pipeline.id)
        p.should === @pipeline
      end

      it "should persist pipeline stages" do
        p1 = SamplePipeline.new
        p1.stages.each {|stage| stage.id.should be_nil}
        lambda {p1.save!}.should_not raise_error
        p1.stages.each {|stage| stage.id.should_not be_nil}
        # 
        # p2 = SamplePipeline.find(p1.id)
        # p2.stages.should === p1.stages
      end
    end
    
    describe "- execute (success)" do
      before(:each) do
        @pipeline = SamplePipeline.new
      end

      it "should execute each stage" do
        @pipeline.stages.each { |stage| stage.should_not be_executed }
        
        @pipeline.execute

        @pipeline.stages.each { |stage| stage.should be_executed }
      end
      
      it "should update stage status after finished" do
        @pipeline.execute
        @pipeline.stages.each { |stage| stage.status.should == :completed }
      end
      
      it "should update pipeline status after all stages finished" do
        @pipeline.execute
        @pipeline.status.should == :completed
      end
    end
    
    describe "- execute (irrecoverable error)" do
    end
  end
end
