require 'rubygems'
require 'spec'
gem 'activerecord'
gem 'collectiveidea-delayed_job'

require File.join(File.dirname(__FILE__), '..', 'init')
require File.join(File.dirname(__FILE__), 'database_integration_helper')

ActiveRecord::Base.logger = Logger.new('pipeline.log')

at_exit do
  File.delete("pipeline.log") if File.exists?("pipeline.log")
end