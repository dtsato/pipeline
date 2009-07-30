require File.join(File.dirname(__FILE__), '..', 'init')
require File.join(File.dirname(__FILE__), '..', 'spec', 'database_integration_helper')
ActiveRecord::Base.logger = Logger.new(STDOUT)

class Step1 < Pipeline::Stage::Base
  def run
    puts("Started step 1")
    puts("Raising user-recoverable error")
    raise Pipeline::RecoverableError.new("require your action", true)
  end
end

class Step2 < Pipeline::Stage::Base
  def run
    puts("Started step 2")
    sleep 3
    puts("Finished step 2")
  end
end

class TwoStepPipeline < Pipeline::Base
  define_stages Step1 >> Step2
end

id = Pipeline.start(TwoStepPipeline.new)

Delayed::Worker.new.start

# CTRL-C to execute the cancelling, since we want to cancel after the stage failed, but
# Worker is blocking the process on the previous line
Pipeline.cancel(id)
p Pipeline::Base.find(id)
