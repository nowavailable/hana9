require 'test_helper'

class RequestDeliveryTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.local(2017, 10, 28, 9))
  end
  test "decide only one shop" do
    loaded = create_context_fixtures(
      "order_for_only_one_shop",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders , :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )

    inputs = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    raise() if inputs.length == 0
    ctx = Context::RequestDelivery.new
    inputs.each do |order_detail|
      ctx.propose(order_detail.order)
      assert ctx.shops_fullfilled_profitable
      assert_equal ctx.shops_fullfilled_profitable.length, 1, "受注候補店舗1件"
      assert ctx.shops_fullfilled_leveled
      assert_equal ctx.shops_fullfilled_leveled.length, 1, "受注候補店舗1件"
      assert_equal ctx.shops_partial_profitable, [], "部分受注候補店舗なし"
      assert_equal ctx.shops_partial_leveled, [], "部分受注候補店舗なし"
      break
    end
  end

  test "choice shop" do
    loaded = create_context_fixtures(
        "order_multiple_shop",
        :cities, :cities_shops, :merchandises,
        :order_details, :orders , :requested_deliveries,
        :rule_for_ships, :ship_limits, :shops
    )

    inputs = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    # raise() if inputs.length == 0
    ctx = Context::RequestDelivery.new
    inputs.each do |order_detail|
      ctx.propose(order_detail.order)
      pp ctx.shops_fullfilled_profitable
      pp ctx.shops_fullfilled_leveled
      pp ctx.shops_partial_profitable
      pp ctx.shops_partial_leveled
      p "--------------------------"
    end
  end
end