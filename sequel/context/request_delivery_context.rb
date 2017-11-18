class RequestDeliveryContext
  #
  # "管理者が、注文を配送指示したい。"
  #
  attr_accessor :shops_fullfilled_profitable,
    :shops_fullfilled_leveled,
    :shops_partial_profitable,
    :shops_partial_leveled

  # ある注文に対して、それを配送できる加盟店の候補をリストを提示する。
  def propose(order)
    order.extend DeliveryProposer

    @shops_fullfilled_profitable = order.shops_fullfilled_profitable
    @shops_fullfilled_leveled = order.shops_fullfilled_leveled
    @shops_partial_profitable = order.shops_partial_profitable
    @shops_partial_leveled = order.shops_partial_leveled
  end
end