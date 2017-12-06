require_relative "i_order_operator"
module OrderAcceptor
  include IOrderOperator
  attr_accessor :order
  # 注入された先の宿主オブジェクトが適正かどうかチェック。
  # ・order は、お届け希望日と、配送先住所（市区町村ID？）と、数量を持ち、それにアクセスできること。
  # など。
  def self.extended(order)

  end

  # 注文に含まれる注文明細のうち、
  # 成立可能なもののリストを返す。
  def acceptable_list
    order_details = []
    return order_details
  end

  # 発番

end