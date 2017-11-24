module Context::ContextAccessor
  def context
    Thread.current[:context]
  end
  def context=(ctx)
    Thread.current[:context] = ctx
  end
  # コンテキスト内でこのブロックを使用すると、そのブロック内で
  # 利用される（ロール等の）オブジェクト内から、
  # コンテキストのアクセサメソッドにアクセス可能になる。
  # （コンテキストのアクセサメソッドをスレッドローカルな変数として共有するから）
  # 注入された部品であるロールが、注入される母体であるコンテキストの
  # 構造を知っている状態にできるということ。つまりはIoCパターンの実現。
  def execute_in_context
    # 退避処理
    origin_context_if_exist = self.context
    # 具体的なContexインスタンスを、Thread.current[:context] に代入。
    self.context = self
    yield
    # 退避したオブジェクトを書き戻し。
    self.context = origin_context_if_exist
  end
end