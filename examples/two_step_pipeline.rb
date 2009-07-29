require File.join(File.dirname(__FILE__), '..', 'init')
require File.join(File.dirname(__FILE__), '..', 'spec', 'database_integration_helper')
ActiveRecord::Base.logger = Logger.new(STDOUT)

class Step1 < Pipeline::Stage::Base
  def perform
    puts("Started step 1")
    sleep 2
    puts("Finished step 1")
  end
end

class Step2 < Pipeline::Stage::Base
  def perform
    puts("Started step 2")
    sleep 3
    puts("Finished step 2")
  end
end

class TwoStepPipeline < Pipeline::Base
  define_stages Step1 >> Step2
end

Pipeline.start(TwoStepPipeline.new)

Delayed::Worker.new.start