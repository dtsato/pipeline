require 'rubygems'
require 'activerecord'
gem 'collectiveidea-delayed_job'
autoload :Delayed, 'delayed_job'

$: << File.dirname(__FILE__)
require 'pipeline/api_methods'
require 'pipeline/base'
require 'pipeline/stage/base'
require 'pipeline/worker_engine'

module Pipeline
  class InvalidPipelineError < StandardError; end
  
  extend(ApiMethods)
end