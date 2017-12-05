require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.local(2017, 10, 28, 9))
  end
  test "order for only one shop" do
    loaded = create_context_fixtures(
      "order_for_only_one_shop",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders , :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )

    inputs = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    raise() if inputs.length == 0
    ctx = Context::Order.new
    inputs.map{|d|d.order}.each do |order|
      ctx.order = order
      ctx.accept_check
      shop = ctx.candidate_shops.first.shops.first
      assert shop
      break
    end

  end
end