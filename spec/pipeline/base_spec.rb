require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class FirstStage < Pipeline::Stage::Base
  def initialize(*args)
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

      it "should associate pipeline stages with pipeline instance" do
        p1 = SamplePipeline.new
        p1.save!
        
        p1.stages.each {|stage| stage.pipeline.should === p1}
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
