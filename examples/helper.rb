require 'rubygems'
gem 'activerecord'
gem 'collectiveidea-delayed_job', :lib => 'delayed_job'

require File.join(File.dirname(__FILE__), '..', 'init')
require File.join(File.dirname(__FILE__), '..', 'spec', 'database_integration_helper')
ActiveRecord::Base.logger = Logger.new(STDOUT)