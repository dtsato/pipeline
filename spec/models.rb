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
end
