require 'test_helper'

class OrderTest < ActiveSupport::TestCase
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
    inputs = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    ctx = Context::Order.new
    inputs.
      map {|order_detail| order_detail.order}.
      uniq.
      select {|o|
        o.order_code == expected_order["order_code"].to_s
      }.each do |order|
      ctx.order = order
      ctx.accept_check
      # pp ctx.candidate_shops
      # pp "---------"
      shops = loaded[8].fixtures
      expected_candidate_shop = [
        shops["shop_4"]["code"].to_s,
        shops["shop_1"]["code"].to_s,
        shops["shop_5"]["code"].to_s,
        shops["shop_3"]["code"].to_s
      ]
      ctx.candidate_shops.each{|e|
        assert_not_empty(e.shops.map{|s|s.code} & expected_candidate_shop)
      }
    end
  end

  #
  # 明細を完受注できる店舗が無い。
  # しかし候補店舗のリソ−スをすべて足せば、その注文明細を受けられる状態。
  # 注文可能。
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
    inputs = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    ctx = Context::Order.new
    inputs.
      map {|order_detail| order_detail.order}.
      uniq.
      select {|o|
        o.order_code == expected_order["order_code"].to_s
      }.each do |order|
      ctx.order = order
      ctx.accept_check
      # pp ctx.candidate_shops
      # pp "---------"
      ctx.candidate_shops.each{|e|
        assert_not_empty(e.shops, "注文可能")
      }
    end
  end

  #
  # 注文完受注可能店舗と、明細のみ完受注可能店舗の混在する状態
  # 注文可能。
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
    ctx = Context::Order.new
    inputs.
      map {|order_detail| order_detail.order}.
      uniq.
      select {|o|
        o.order_code == expected_order["order_code"].to_s
      }.each do |order|
      ctx.order = order
      ctx.accept_check
      # pp ctx.candidate_shops
      # pp "---------"
      expected_shop = loaded[8].fixtures["shop_3"]["code"].to_s
      all_shops = ctx.candidate_shops.map{|e| e.shops}.flatten.map{|s| s.code}
      assert_equal(
        all_shops.length - (all_shops - [expected_shop]).length,
        ctx.candidate_shops.length,
        "注文可能"
      )
    end
  end

end