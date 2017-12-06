require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.local(2017, 10, 29, 9))
  end
  test "order for only one shop" do
    loaded = create_context_fixtures(
      "order_for_only_one_shop",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders , :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )

    inputs = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    raise("対象デ−タ件数 #{inputs.length} 件 というのは想定外です。") if inputs.length != 1
    ctx = Context::Order.new
    inputs.map{|d|d.order}.uniq.each do |order|
      ctx.order = order
      ctx.accept_check
      shop = ctx.candidate_shops.first.shops.first
      assert shop
      break
    end
  end

  test "order to multiple shop" do
    loaded = create_context_fixtures(
      "order_multiple_shop",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders, :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )
    inputs = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    ctx = Context::Order.new
    inputs.map{|d|d.order}.uniq.each do |order|
      ctx.order = order
      ctx.accept_check
      pp ctx.candidate_shops
      pp "---------"
    end
  end

end