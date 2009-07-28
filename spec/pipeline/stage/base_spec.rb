require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

module Pipeline
  module Stage
    describe Base do
      it "should start with status not_started" do
        Base.new.status.should == :not_started
      end
      
      it "should allow completion of stage" do
        stage = Base.new
        stage.complete
        stage.status.should == :completed
      end
    end
  end
end
