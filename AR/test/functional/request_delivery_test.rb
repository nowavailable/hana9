require 'test_helper'

class RequestDeliveryTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.local(2017, 11, 20, 9))
    # Timecop.freeze(Time.now.to_date - 44.days + 6.to_i.day)
  end

  #
  # 注文明細すべてを受けられる店舗ばかりのとき
  #
  test "shoud be shops can take all order_details" do
    loaded = create_context_fixtures(
      "order_fullfilled_shops",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders, :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )

    # 期待を満たしているOrder
    order = loaded[4].fixtures["order_6"]

    inputs = OrderDetail.includes(:requested_deliveries).
      where(:requested_deliveries => {id: nil})
    ctx = Context::RequestDelivery.new
    inputs.
      map {|order_detail| order_detail.order}.
      uniq.
      select {|o|
        # o.order_code.to_s == "104" or
        o.order_code == loaded[4].fixtures["order_6"]["order_code"].to_s
      }.each do |order|

      ctx.propose(order)
      # p "--------------------------"
      # pp ctx.shops_fullfilled_profitable
      # p "----"
      # pp ctx.shops_fullfilled_leveled
      # p "----"
      # pp ctx.shops_partial_profitable
      # p "----"
      # pp ctx.shops_partial_leveled
      # p "■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
      assert_not_empty(ctx.shops_fullfilled_profitable)
      assert_equal(ctx.shops_fullfilled_profitable.length,
        ctx.shops_fullfilled_leveled.length)
      assert_equal(ctx.shops_partial_profitable.length, 0)
      assert_equal(ctx.shops_partial_leveled.length, 0)

      # ソ−トが期待どおりである
      shops = loaded[8].fixtures
      assert_equal(
        ctx.shops_fullfilled_profitable.map{|e|e.code},
        [
          shops["shop_4"]["code"].to_s,
          shops["shop_1"]["code"].to_s,
          shops["shop_5"]["code"].to_s,
          shops["shop_3"]["code"].to_s
        ]
      )
      assert_equal(
        ctx.shops_fullfilled_leveled.map{|e|e.code},
        [
          shops["shop_1"]["code"].to_s,
          shops["shop_3"]["code"].to_s,
          shops["shop_5"]["code"].to_s,
          shops["shop_4"]["code"].to_s
        ]
      )
    end
  end
end