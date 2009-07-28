require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Pipeline
  describe WorkerEngine do
    it "should accept pipeline instance id" do
      engine = WorkerEngine.new('1')
      engine.pipeline_instance_id.should == '1'
    end
    
    it "should find pipeline instance and execute" do
      pipeline_instance = Pipeline::Base.new
      Pipeline::Base.should_receive(:find).with('1').and_return(pipeline_instance)
      pipeline_instance.should_receive(:execute)
      
      engine = WorkerEngine.new('1')
      engine.perform
    end
  end
end
