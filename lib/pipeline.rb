require 'rubygems'
require 'activerecord'
gem 'collectiveidea-delayed_job'
autoload :Delayed, 'delayed_job'

$: << File.dirname(__FILE__)
require 'pipeline/core_ext/symbol_attribute'
require 'pipeline/core_ext/transactional_attribute'
require 'pipeline/api_methods'
require 'pipeline/base'
require 'pipeline/errors'
require 'pipeline/stage/base'

module Pipeline
  extend(ApiMethods)
end