require 'test_helper'

class ConsumerOrderTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.local(2017, 11, 16, 9))
  end
  test "order accept easy" do
    loaded = create_context_fixtures(
      "consumer_order",
      :shops, :cities, :cities_shops, :merchandises,
      :rule_for_ships, :ship_limits
    )
    assert true

    # 過去の実績を含むデ−タをロ−ドして
    # 未決のOrderをとり、処理実行
    # 個々の条件を満たしているか。また、対偶もとる

  end
end