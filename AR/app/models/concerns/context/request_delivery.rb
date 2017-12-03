#
# "管理者が、注文を配送指示したい。"
#
class Context::RequestDelivery
  include ContextAccessor
  attr_accessor :shops_fullfilled_profitable,
    :shops_fullfilled_leveled,
    :shops_partial_profitable,
    :shops_partial_leveled,
    :order, :candidate_shops

  # @shops_fullfilled_profitable と @shops_fullfilled_leveled は、
  # 単にShopのリストであればよい。対して、
  # @shops_partial_profitable と @shops_partial_leveled は、
  # 以下の型のリストとする。
  # TODO: 操作フォ−ムを画面に出力するのが前提であれば、それに適した型を用意する必要がある。
  CandidateShop = Struct.new(:order_detail, :shops)

  def initialize(order=nil)
    @shops_fullfilled_profitable = []
    @shops_fullfilled_leveled = []
    @shops_partial_profitable = []
    @shops_partial_leveled = []
    @candidate_shops = []
    @order = order if order
  end

  # ある注文に対して、それを配送できる加盟店の候補をリストを提示する。
  def propose(order)
    @order ||= order
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