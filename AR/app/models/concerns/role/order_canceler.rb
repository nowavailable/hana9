module Role::OrderCanceler
  include IOrderManipulator
  attr_accessor :order

  def self.extended(order)
  end

  # 注文に含まれる注文明細のうち、
  # 取り消し可能なもののリストを返す。
  def build_acceptable_list
    order_details = []
    return order_details
  end
end