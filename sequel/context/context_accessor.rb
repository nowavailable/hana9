module ContextAccessor
  def context
    Thread.current[:context]
  end
  def context=(ctx)
    Thread.current[:context] = ctx
  end
  def execute_in_context
    origin_context_if_exist = self.context
    self.context = self
    yield
    self.context = origin_context_if_exist
  end
end