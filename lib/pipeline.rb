autoload :ActiveRecord, 'active_record'
autoload :Delayed, 'delayed_job'

$: << File.dirname(__FILE__)
require 'pipeline/core_ext/symbol_attribute'
require 'pipeline/core_ext/transactional_attribute'
require 'pipeline/api_methods'
require 'pipeline/base'
require 'pipeline/errors'
require 'pipeline/stage/base'

# Please refer to Pipeline::Base and Pipeline::Stage::Base for detailed documentation
module Pipeline
  extend(ApiMethods)
end