require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.local(2017, 10, 27, 9))
  end
  test "order accept easy" do
    loaded = create_context_fixtures(
      "order",
      :cities, :cities_shops, :merchandises,
      :order_details, :orders , :requested_deliveries,
      :rule_for_ships, :ship_limits, :shops
    )

    mikt = OrderDetail.includes(:requested_deliveries).where(:requested_deliveries => {id: nil})
    ctx = Context::Order.new
    mikt.map{|d|d.order}.each do |order|
      ctx.order = order
      ctx.accept_check
      pp ctx.candidate_shops
      pp "----------------------------------"
      pp "----------------------------------"
    end

    assert true

    # 過去の実績を含むデ−タをロ−ドして
    # 未決のOrderをとり、処理実行
    # 個々の条件を満たしているか。また、対偶もとる

  end
end