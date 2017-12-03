require 'test_helper'

class RequestDeliveryTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.local(2017, 11, 16, 9))
  end
  test "order accept easy" do
    loaded = create_context_fixtures(
      "order",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders , :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )

    # 過去の実績を含むデ−タをロ−ドして
    # 未決のOrderをとり、処理実行
    # 個々の条件を満たしているか。また、対偶もとる
    # mikt = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    mikt = OrderDetail.all.select{|od| od.requested_deliveries.blank?}
    ctx = Context::RequestDelivery.new
    ctx.propose(mikt[0].order)

    assert true
  end
end