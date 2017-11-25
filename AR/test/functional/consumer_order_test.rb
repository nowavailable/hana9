require 'test_helper'

class ConsumerOrderTest < ActiveSupport::TestCase
  test "the truth" do
    loaded = create_context_fixtures(
      "consumer_order",
      :shops, :cities, :cities_shops, :merchandises,
      :rule_for_ships, :ship_limits
    )
    assert true
  end
end