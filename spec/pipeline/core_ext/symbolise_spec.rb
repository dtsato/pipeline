require File.dirname(__FILE__) + '/../../spec_helper'

# Reusing stage table to simplify database integration tests
class FakeForSymbolise < ActiveRecord::Base
  set_table_name :pipeline_stages
  
  symbolise :status
end

module Pipeline
  describe Symbolise do
    it "should extend active record to allow symbol attributes to be saved as string" do
      stage = FakeForSymbolise.new(:status => :started)
      stage.save!
      stage.status.should == :started
      stage.reload.status.should == :started
      
      stage.status = :finished
      stage.save!
      stage.status.should == :finished
      stage.reload.status.should == :finished
    end

    it "should extend Symbol to allow symbol attributes in conditions" do
      stages = FakeForSymbolise.find(:all, :conditions => ['status = ?', :started])
      stages.should be_empty
      
      FakeForSymbolise.create(:status => :started)

      stages = FakeForSymbolise.find(:all, :conditions => ['status = ?', :started])
      stages.size.should == 1
    end
  end
end
