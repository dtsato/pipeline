require File.join(File.dirname(__FILE__), '..', 'init')
require File.join(File.dirname(__FILE__), '..', 'spec', 'database_integration_helper')
ActiveRecord::Base.logger = Logger.new(STDOUT)

class Step1 < Pipeline::Stage::Base
  def run
    puts("Started step 1")
    sleep 2
    puts("Finished step 1")
  end
end

class Step2 < Pipeline::Stage::Base
  def run
    puts("Started step 2")
    # Will fail on the first time, but pass on the second
    if attempts == 1
      puts("Raising user-recoverable error")
      raise Pipeline::RecoverableError.new("require your action", true)
    end
    puts("Finished step 2")
  end
end

class TwoStepPipeline < Pipeline::Base
  define_stages Step1 >> Step2
end

id = Pipeline.start(TwoStepPipeline.new)

Pipeline.resume(id)

Delayed::Worker.new.start