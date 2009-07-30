require File.dirname(__FILE__) + '/../../spec_helper'

# Reusing stage table to simplify database integration tests
class FakeForSymbolAttribute < ActiveRecord::Base
  set_table_name :pipeline_stages
  
  symbol_attr :status
end

module Pipeline
  describe SymbolAttribute do
    before(:each) do
      FakeForSymbolAttribute.delete_all
    end
    
    it "should extend active record to allow symbol attributes to be saved as string" do
      obj = FakeForSymbolAttribute.new(:status => 'started')
      obj.save!
      obj.status.should == :started
      obj.reload.status.should == :started
      
      obj.status = 'finished'
      obj.save!
      obj.status.should == :finished
      obj.reload.status.should == :finished
    end

    it "should extend Symbol to allow symbol attributes in conditions" do
      objs = FakeForSymbolAttribute.find(:all, :conditions => ['status = ?', :started])
      objs.should be_empty
      
      FakeForSymbolAttribute.create(:status => :started)

      objs = FakeForSymbolAttribute.find(:all, :conditions => ['status = ?', :started])
      objs.size.should == 1
    end
  end
end
