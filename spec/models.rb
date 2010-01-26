class StubStage < Pipeline::Stage::Base
  def run
    @executed = true
  end
  
  def executed?
    !!@executed
  end
end

class FirstStage < StubStage; end

class SecondStage < StubStage; end

class FailedStage < StubStage
  def run
    super
    raise StandardError.new
  end
end

class IrrecoverableStage < StubStage
  def run
    super
    raise Pipeline::IrrecoverableError.new("message")
  end
end

class RecoverableInputRequiredStage < StubStage
  def run
    super
    raise Pipeline::RecoverableError.new("message", true)
  end
end

class RecoverableStage < StubStage
  def run
    super
    raise Pipeline::RecoverableError.new("message")
  end
end

class GenericErrorStage < StubStage
  def run
    super
    raise Exception.new
  end
end

class SamplePipeline < Pipeline::Base
  define_stages FirstStage >> SecondStage
  
  before_pipeline :before_pipeline_callback
  after_pipeline :after_pipeline_callback
  
  private
  def before_pipeline_callback; end
  def after_pipeline_callback; end
end

class SampleStage < Pipeline::Stage::Base
  before_stage :before_stage_callback
  after_stage :after_stage_callback
  
  def run
    # nothing...
  end
  
  private
  def before_stage_callback; end
  def after_stage_callback; end
end

class SampleStageWithCallback < Pipeline::Stage::Base
  attr_writer :before_stage_executed, :after_stage_executed
  
  before_stage do |stage|
    puts "called"
    stage.before_stage_executed += 1
  end
  
  after_stage do |stage|
    stage.after_stage_executed += 1
  end
  
  def run
    # nothing...
  end
  
  def before_stage_executed
    @before_stage_executed ||= 0
  end
  
  def after_stage_executed
    @after_stage_executed ||= 0
  end  
end

class SamplePipelineWithCallbacks < Pipeline::Base
  define_stages SampleStageWithCallback >> SampleStage
end