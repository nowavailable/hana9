require 'test_helper'

class RequestDeliveryTest < ActiveSupport::TestCase
  def setup
    # Timecop.freeze(Time.local(2017, 11, 20, 9))
    # Timecop.freeze(Time.now.to_date - 44.days + 6.to_i.day)
  end

  #
  # 注文明細すべてを受けられる店舗が複数ある.
  #
  test "shoud be shops can take all order_details" do
    Timecop.freeze(Time.local(2017, 11, 20, 9))
    loaded = create_context_fixtures(
      "order_fullfilled_shops",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders, :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )

    # 期待を満たしているOrder
    expected_order = loaded[4].fixtures["order_6"]

    inputs = OrderDetail.includes(:requested_deliveries).
      where(:requested_deliveries => {id: nil})
    ctx = Context::RequestDelivery.new
    inputs.
      map {|order_detail| order_detail.order}.
      uniq.
      select {|o|
        o.order_code == expected_order["order_code"].to_s
      }.each do |order|

      ctx.propose(order)
      # p "--------------------------"
      # pp ctx.shops_fullfilled_profitable
      # pp ctx.shops_fullfilled_leveled
      # pp ctx.shops_partial_profitable
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

  #
  # 明細を完受注できる店舗が無い。
  # しかし候補店舗のリソ−スをすべて足せば、その注文明細を受けられる状態
  #
  test "should candidate shops can process order-details partially" do
    Timecop.freeze(Time.local(2017, 11, 20, 9))
    loaded = create_context_fixtures(
      "order_partial_shops",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders, :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )
    # 期待を満たしているOrder
    expected_order = loaded[4].fixtures["order_2"]
    inputs = OrderDetail.includes(:requested_deliveries).
      where(:requested_deliveries => {id: nil})
    ctx = Context::RequestDelivery.new
    inputs.
      map {|order_detail| order_detail.order}.
      uniq.
      select {|o|
        o.order_code == expected_order["order_code"].to_s
      }.each do |order|

      ctx.propose(order)
      # p "--------------------------"
      # pp ctx.shops_fullfilled_profitable
      # pp ctx.shops_fullfilled_leveled
      # pp ctx.shops_partial_profitable
      # pp ctx.shops_partial_leveled
      # p "■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
      assert_empty(ctx.shops_fullfilled_profitable)
      assert_equal(ctx.shops_fullfilled_profitable.length,
        ctx.shops_fullfilled_leveled.length)
      assert_not_empty(ctx.shops_partial_profitable)
      assert_equal(ctx.shops_partial_profitable.length,
        ctx.shops_partial_leveled.length)

    end
  end

  #
  # 注文完受注可能店舗と、明細のみ完受注可能店舗の混在する状態
  #
  test "shoud some shops can take all order_details, some cannnot take all order_details" do
    Timecop.freeze(Time.local(2017, 11, 21, 9))
    loaded = create_context_fixtures(
      "order_fullfilled_and_partially",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders, :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )
    # 期待を満たしているOrder
    expected_order = loaded[4].fixtures["order_4"]
    inputs = OrderDetail.includes(:requested_deliveries).
      where(:requested_deliveries => {id: nil})
    ctx = Context::RequestDelivery.new
    inputs.
      map {|order_detail| order_detail.order}.
      uniq.
      select {|o|
        o.order_code == expected_order["order_code"].to_s
      }.each do |order|
      ctx.propose(order)

      # 全明細受注可能な店舗リストと、一部明細のみ受注可能な店舗リストとに、要素の重複は無い。
      assert_empty(ctx.shops_fullfilled_profitable & ctx.shops_partial_profitable)
    end
  end
end