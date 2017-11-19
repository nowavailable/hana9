module ContextAccessor
  def context
    Thread.current[:context]
  end
  def context=(ctx)
    Thread.current[:context] = ctx
  end
  def execute_in_context
    old_context = self.context
    self.context = self
    yield
    self.context = old_context
  end
end