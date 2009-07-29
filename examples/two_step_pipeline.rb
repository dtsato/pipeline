require File.join(File.dirname(__FILE__), '..', 'init')
require File.join(File.dirname(__FILE__), '..', 'spec', 'spec_helper')

class Step1 < Pipeline::Stage::Base
  def execute
    logger.info("Started step 1")
    sleep 2
    logger.info("Finished step 1")
  end
end

class Step2 < Pipeline::Stage::Base
  def execute
    logger.info("Started step 2")
    sleep 3
    logger.info("Finished step 2")
  end
end

class TwoStepPipeline < Pipeline::Base
  define_stages Step1 >> Step2
end

Pipeline.start(TwoStepPipeline.new)

Delayed::Worker.new.start