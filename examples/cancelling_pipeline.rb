require File.join(File.dirname(__FILE__), 'helper')

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

Delayed::Job.work_off

Pipeline.cancel(id)
puts("Pipeline is now #{Pipeline::Base.find(id).status}")
