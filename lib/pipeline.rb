require File.join(File.dirname(__FILE__), 'pipeline', 'base')
require File.join(File.dirname(__FILE__), 'pipeline', 'api_methods')

module Pipeline
  class InvalidPipelineError < StandardError; end
  
  extend(ApiMethods)
end