module hana9

open util/boolean
sig Boundary { val: disj one Int }
one sig Now { val: one Int } { val = 6}

sig City {
  cities_shops: set CitiesShop,
  order_details: set OrderDetail,
  label: one Boundary
}
sig CitiesShop {
  shop: one Shop,
  city: one City
}
sig Merchandise {
  order_details: set OrderDetail,
  rule_for_ships: set RuleForShip,
  label: one Boundary,
  price: one Boundary
}
sig OrderDetail {
  merchandise: one Merchandise,
  city: one City,
  order: one Order,
  requested_deliveries: set RequestedDelivery,
  seq_code: one Boundary,
  expected_date: one Boundary,
  quantity: one Boundary
}
sig Order {
  order_details: set OrderDetail,
  order_code: one Boundary,
  ordered_at: one Boundary
}
sig RequestedDelivery {
  shop: one Shop,
  order_detail: one OrderDetail,
  order_code: one Boundary,
  quantity: one Boundary
}
sig RuleForShip {
  shop: one Shop,
  merchandise: one Merchandise,
  interval_day: one Boundary,
  quantity_limit: one Boundary,
  quantity_available: one Boundary
}
sig ShipLimit {
  shop: one Shop,
  expected_date: one Boundary
}
sig Shop {
  cities_shops: set CitiesShop,
  requested_deliveries: set RequestedDelivery,
  rule_for_ships: set RuleForShip,
  ship_limits: set ShipLimit,
  code: one Boundary,
  label: one Boundary,
  delivery_limit_per_day: one Boundary,
  mergin: one Boundary
}

fact {
  Shop<:cities_shops = ~(CitiesShop<:shop)
  City<:cities_shops = ~(CitiesShop<:city)
  Merchandise<:order_details = ~(OrderDetail<:merchandise)
  City<:order_details = ~(OrderDetail<:city)
  Order<:order_details = ~(OrderDetail<:order)
  Shop<:requested_deliveries = ~(RequestedDelivery<:shop)
  OrderDetail<:requested_deliveries = ~(RequestedDelivery<:order_detail)
  Shop<:rule_for_ships = ~(RuleForShip<:shop)
  Merchandise<:rule_for_ships = ~(RuleForShip<:merchandise)
  Shop<:ship_limits = ~(ShipLimit<:shop)
  all e,e':CitiesShop | e != e' => (e.shop->e.city) != (e'.shop->e'.city)
  all e,e':OrderDetail | e != e' => (e.seq_code->e.order->e.merchandise) != (e'.seq_code->e'.order->e'.merchandise)
  all e,e':Order | e != e' => (e.order_code) != (e'.order_code)
  all e,e':RequestedDelivery | e != e' => (e.shop->e.order_detail) != (e'.shop->e'.order_detail)
  all e,e':RuleForShip | e != e' => (e.shop->e.merchandise) != (e'.shop->e'.merchandise)
  all e,e':ShipLimit | e != e' => (e.shop->e.expected_date) != (e'.shop->e'.expected_date)
  all e,e':Shop | e != e' => (e.code) != (e'.code)
}

-- ユーティリティ関数
pred b_gte(v,v': Int) { vCheck[v] implies eq[1,1] else gte[v,v'] }
pred b_gt(v,v': Int) { vCheck[v] implies eq[1,1] else gt[v,v'] }
pred b_lte(v,v': Int) { vCheck[v] implies eq[1,2] else lte[v,v'] }
pred b_lt(v,v': Int) { vCheck[v] implies eq[1,2] else lt[v,v'] }
pred vCheck(v: Int) {lt[v,0]}
