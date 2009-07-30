require File.join(File.dirname(__FILE__), '..', 'init')
require File.join(File.dirname(__FILE__), '..', 'spec', 'database_integration_helper')
ActiveRecord::Base.logger = Logger.new(STDOUT)

class Step1 < Pipeline::Stage::Base
  def run
    puts("Started step 1")
    # Will fail on the first time, but pass on the second
    if attempts == 1
      puts("Raising auto-recoverable error")
      raise Pipeline::RecoverableError.new
    end
    puts("Finished step 1")
  end
end

class Step2 < Pipeline::Stage::Base
  def run
    puts("Started step 2")
    # Will fail on the first time, but pass on the second
    if attempts == 1
      puts("Raising another auto-recoverable error")
      raise Pipeline::RecoverableError.new
    end
    puts("Finished step 2")
  end
end

class TwoStepPipeline < Pipeline::Base
  define_stages Step1 >> Step2
end

Pipeline.start(TwoStepPipeline.new)

Delayed::Worker.new.start