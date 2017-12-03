open hana9

module hana9_order

fact ビジネスロジック上自明な {
  // quantity系としきい値系は、正の数
  all r: RuleForShip | 
    gt[r.interval_day.val, 0] && gt[r.quantity_limit.val, 0] && gt[r.quantity_available.val, 0]
  all d: OrderDetail | gt[d.quantity.val, 0]
  all r: RequestedDelivery | gt[r.quantity.val, 0]
  // OrderDetail.expected_date も、算術演算の対象なので、正の数とする。
  all d: OrderDetail | gt[d.expected_date.val, 0]

  // 未決の注文明細の日付は、本日以降であること。
  all d: OrderDetail | #(d<:requested_deliveries) = 0 => gt[d.expected_date.val, Now.val]
  // 配達希望日は注文日より未来
  all o: Order | 
    all e_date: o.order_details.expected_date | e_date.val > o.ordered_at.val
  // ひとつの注文明細に複数の配達指示がある場合、
  // それは異なる店舗によって受け持たれている。
  all d: OrderDetail |
    #(d<:requested_deliveries) = #(d<:requested_deliveries.shop) 
  // 値の異なっていて欲しい、マスタ系レコード
  all c,c': City | c != c' => c.label.val != c'.label.val
  all s,s': Shop | s != s' => (s.label.val !=  s'.label.val) && (s.code.val != s'.code.val)
  all m,m': Merchandise | m != m' => m.label.val != m'.label.val
  // コードの一貫性
  all d: OrderDetail | 
    let codVal = d.order.order_code.val | 
      all req, req': d.requested_deliveries.order_code.val |
        req != req' => (req.order_code.val = req'.order_code.val) 
          && (req.order_code.val = codVal)
  // 部分的に明細が未決の注文は、無いものとする？あるいは許容？
  some o: Order | o.order_details.requested_deliveries = none
  one o: Order | #(o.order_details.requested_deliveries) != #(o.order_details)
}
fact 数量 {
  // 数量のキャパシティに沿った受注がなされていること
  all req: RequestedDelivery |
    lte[req.quantity.val, 受注quantityリミット[req].val]
  // ひとつの注文明細に複数の配達指示がある場合、
  // そのどちらかは数量リミットに達している。
  all d: OrderDetail |
    gt[#(d<:requested_deliveries), 1] iff
      (some req: d.requested_deliveries | req.quantity = 受注quantityリミット[req])
  // また、配達指示の個数が注文明細の個数と合っていること 
  all d: OrderDetail | d.requested_deliveries != none =>
    sum[d.requested_deliveries.quantity.val] = d.quantity.val
}
fact 配達地域 {
	all d: OrderDetail |
    // 配達可能地域定義に沿った受注がなされていること
    OrderDetail.(d<:requested_deliveries.shop) in 地域的に受注可能である[d]
}
fact 配達リソース {
  all s: Shop |
    all dateVal: Shop.(s<:requested_deliveries.order_detail.expected_date.val), 
        lim: s.ship_limits, details: s.requested_deliveries.order_detail |
      let worksOnThatDay = (details<:expected_date):>(Boundary->dateVal & Boundary<:val).Int |
        #(worksOnThatDay) = s.delivery_limit_per_day.val
        and
        #(worksOnThatDay) <= #((lim<:expected_date):>(Boundary->dateVal & Boundary<:val).Int)
}
fun 受注quantityリミット (req: RequestedDelivery) : one Boundary {
  let rule = (req.shop.rule_for_ships->req.order_detail.merchandise).Merchandise |
    quantityリミット[req.order_detail.expected_date, rule]
}
fun quantityリミット(date: Boundary, rule: RuleForShip) : Boundary {
  gte[date.val.minus[Now.val], rule.interval_day.val] implies
    rule.quantity_limit else rule.quantity_available
}
fun 地域的に受注可能である (d: OrderDetail) : set Shop {
  ((CitiesShop->(d.city) & CitiesShop<:city).City).shop
}

fact テスト上恣意的な {
  // 出荷ルールの多様性
  all r,r': RuleForShip | 
    r != r' => (r.quantity_limit != r'.quantity_limit)
      && (r.quantity_available != r'.quantity_available)
  // 複数分担の配達指示
	one d: OrderDetail | gt[#(d<:requested_deliveries), 1]
  // 未決の注文明細
	some d: OrderDetail | d.requested_deliveries = none
  // 配達先のカーディナリティ
  #(CitiesShop.city) > 3
}

pred 受注余力有店舗and未決注文明細 {
  // 受注余力があって、まだ受注していない店舗がいくつかあること
  some d: OrderDetail | d.requested_deliveries = none implies
    (some rule: RuleForShip | 
      gte[sum[quantityリミット[d.expected_date, rule].val], d.quantity.val]
      and
      rule in Shop.(地域的に受注可能である[d]<:rule_for_ships) 
    ) and (
    some rule: RuleForShip | 
      not gte[sum[quantityリミット[d.expected_date, rule].val], d.quantity.val]
      and
      rule in Shop.(地域的に受注可能である[d]<:rule_for_ships) 
    ) and (
    some rule: RuleForShip | 
      gte[sum[quantityリミット[d.expected_date, rule].val], d.quantity.val]
      and
      rule not in Shop.(地域的に受注可能である[d]<:rule_for_ships) 
    )
}

run {
  受注余力有店舗and未決注文明細
} for 6 but 5 Shop, 5 City, 8 RequestedDelivery, 5 Int
