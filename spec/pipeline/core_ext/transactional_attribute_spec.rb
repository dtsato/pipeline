require File.dirname(__FILE__) + '/../../spec_helper'

# Reusing stage table to simplify database integration tests
class FakeForTransactionalAttribute < ActiveRecord::Base
  set_table_name :pipeline_stages
  
  transactional_attr :status
end

module Pipeline
  describe TransactionalAttribute do
    it "should extend active record to allow transactional attributes to be saved in a nested transaction" do
      obj = FakeForTransactionalAttribute.create(:status => "started")
      obj.status.should == "started"
      obj.reload.status.should == "started"
      
      obj.status = "finished"
      obj.status.should == "finished"
      obj.reload.status.should == "finished"
    end
  end
end
