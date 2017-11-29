#
# "管理者が、注文を配送指示したい。"
#
class Context::RequestDelivery
  include ContextAccessor
  attr_accessor :shops_fullfilled_profitable,
    :shops_fullfilled_leveled,
    :shops_partial_profitable,
    :shops_partial_leveled,
    :candidate_shops

  # @shops_fullfilled_profitable と @shops_fullfilled_leveled は、
  # 単にShopのリストであればよい。対して、
  # @shops_partial_profitable と @shops_partial_leveled は、
  # 以下の型のリストとする。
  CandidateShop = Struct.new(:order_detail, :shops)

  # ある注文に対して、それを配送できる加盟店の候補をリストを提示する。
  def propose(order)
    execute_in_context do
      order.extend Role::OrderAcceptor
      @candidate_shops = []
      order.build_acceptable_list

      order.extend Role::DeliveryProposer
      @shops_fullfilled_profitable = order.shops_fullfilled_profitable
      @shops_fullfilled_leveled = order.shops_fullfilled_leveled
      @shops_partial_profitable = order.shops_partial_profitable
      @shops_partial_leveled = order.shops_partial_leveled
    end
  end
end