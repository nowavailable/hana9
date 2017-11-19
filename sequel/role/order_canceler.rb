require_relative "i_order_canceler"
module OrderCanceler
  include IOrderCanceler
  attr_accessor :order

  def self.extended(order)
  end

  # 注文に含まれる注文明細のうち、
  # 取り消し可能なもののリストを返す。
  def acceptable_list
    order_details = []
    return order_details
  end
end