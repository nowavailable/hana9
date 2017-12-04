open hana9
module hana9_order
/*-------------------------------------------------------------------------------------------*/
fact ビジネスロジック上自明な {
  // quantity系としきい値系は、正の数。そしてなるべく小さく。
  all r: RuleForShip | 
    pos[r.interval_day.val] && lte[r.interval_day.val, 8] && 
    pos[r.quantity_limit.val] && lte[r.quantity_limit.val, 8] && 
    pos[r.quantity_available.val] && lte[r.quantity_available.val, 8]
  all d: OrderDetail | pos[d.quantity.val] && lte[d.quantity.val, 8]
  all r: RequestedDelivery | pos[r.quantity.val] && lte[r.quantity.val, 8]
  // OrderDetail.expected_date も、算術演算の対象なので同様に。
  all d: OrderDetail | pos[d.expected_date.val]

  // 未決の注文明細の日付は、本日以降であること。
  all d: OrderDetail | #(d<:requested_deliveries) = 0 => b_gt[d.expected_date.val, Now.val]
  // 配達希望日は注文日より未来
  all o: Order | 
    all e_date: o.order_details.expected_date | e_date.val > o.ordered_at.val
  // ひとつの注文明細に複数の配達指示がある場合それは異なる店舗によって受け持たれている。
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
  // 明細がすべて未決の注文もある。
  some o: Order | o.order_details.requested_deliveries = none
  // 部分的に明細が未決の注文は、無いものとする？あるいは許容？
  one o: Order | #(o.order_details.requested_deliveries) != #(o.order_details)
}
fact 数量整合性 {
  // 数量のキャパシティに沿った受注がなされていること
  all req: RequestedDelivery |
    b_lte[req.quantity.val, 受注数量リミット[req].val]
  // ひとつの注文明細に複数の配達指示がある場合、そのどちらかは数量リミットに達している。
  all d: OrderDetail |
    b_gt[#(d<:requested_deliveries), 1] iff
      (some req: d.requested_deliveries | req.quantity = 受注数量リミット[req])
  // また、配達指示の個数が注文明細の個数と合っていること 
  all d: OrderDetail | d.requested_deliveries != none =>
    sum[d.requested_deliveries.quantity.val] = d.quantity.val
}
fact 配達可能地域 {
	all d: OrderDetail |
    // 配達可能地域定義に沿った受注がなされていること
    OrderDetail.(d<:requested_deliveries.shop) in 地域的に受注可能であるShop[d]
}
fact 配達リソース整合性 {
  all s: Shop |
    all dateVal: Shop.(s<:requested_deliveries.order_detail.expected_date.val), 
        lim: s.ship_limits, details: s.requested_deliveries.order_detail |
      let worksOnThatDay = (details<:expected_date):>(Boundary->dateVal & Boundary<:val).Int |
        #(worksOnThatDay) = s.delivery_limit_per_day.val
        and
        #(worksOnThatDay) <= #((lim<:expected_date):>(Boundary->dateVal & Boundary<:val).Int)
}
fun 受注数量リミット (req: RequestedDelivery) : one Boundary {
  let rule = (req.shop.rule_for_ships->req.order_detail.merchandise).Merchandise |
    数量リミット[req.order_detail.expected_date, rule]
}
fun 数量リミット(date: Boundary, rule: RuleForShip) : Boundary {
  b_gte[date.val.minus[Now.val], rule.interval_day.val] implies
    rule.quantity_limit else rule.quantity_available
}
fun 地域的に受注可能であるShop (d: OrderDetail) : set Shop {
  CitiesShop.(((CitiesShop<:city:>d.city).City)<:shop)
}
pred その日は既にふさがっている(date: Boundary, shop: Shop) {
  #(
    ((shop.ship_limits)<:expected_date):>((Boundary->(date.val) & Boundary<:val).Int)
  ) = 0
}
/*-------------------------------------------------------------------------------------------*/
fact テスト上恣意的な {
  // 出荷ルールの多様性
  all r,r': RuleForShip | 
    r != r' => (r.quantity_limit != r'.quantity_limit)
      && (r.quantity_available != r'.quantity_available)
  // マージンの多様性
  all s,s': Shop | 
    s != s' => (s.mergin != s'.mergin)
  // 複数分担の配達指示
	one d: OrderDetail | b_gt[#(d<:requested_deliveries), 1]
  // 未決の注文明細
	some d: OrderDetail | d.requested_deliveries = none
  // 配達先のカーディナリティ
  #(CitiesShop.city) > 3
}
/*-------------------------------------------------------------------------------------------*/
pred 明細完受注可店舗在り(d: OrderDetail) {
  some rule: d.merchandise.rule_for_ships | 明細完受注可[d]
   /** ※恣意的な様相コントロール */
    and (
      let rules = 
        // そのruleの所有者であるShopで絞るRuleForShop と
        ((RuleForShip<:shop):>(rule.shop)).Shop & 
          // と、当該merchandise群で絞るRuleForShop との積集合は
          ((RuleForShip<:merchandise):>(rule.merchandise)).Merchandise | 
            b_gt[#(rules.shop), 2]
    )
}
pred 明細完受注可(d: OrderDetail) {
  some rule: d.merchandise.rule_for_ships |
    b_gte[sum[数量リミット[d.expected_date, rule].val], d.quantity.val]
    and rule.shop in 地域的に受注可能であるShop[d]
    and not その日は既にふさがっている[d.expected_date, rule.shop]
}
pred 明細完受注NG店舗在り(d: OrderDetail) {
  (
    some rule: d.merchandise.rule_for_ships | 
      not b_gte[sum[数量リミット[d.expected_date, rule].val], d.quantity.val]
      and rule.shop in 地域的に受注可能であるShop[d]
      and not その日は既にふさがっている[d.expected_date, rule.shop]
  ) and (
    some rule: d.merchandise.rule_for_ships | 
      b_gte[sum[数量リミット[d.expected_date, rule].val], d.quantity.val]
      and rule.shop not in 地域的に受注可能であるShop[d]
      and not その日は既にふさがっている[d.expected_date, rule.shop]
  )
}
pred 全品受注OK店舗在り(o: Order) {
  all d: o.order_details |
    some rule: d.merchandise.rule_for_ships | 明細完受注可[d]
      and (
        let rules = 
          // そのruleの所有者であるShopで絞るRuleForShop と
          ((RuleForShip<:shop):>(rule.shop)).Shop & 
            // と、当該merchandise群で絞るRuleForShop との積集合は
            ((RuleForShip<:merchandise):>(o.order_details.merchandise)).Merchandise | 
              b_gte[#(rules), #(o.order_details.merchandise)] 
              /** ※恣意的な様相コントロール */
              and b_gt[#(rules), 4]
      )
}

pred 未決注文明細と受注余力有店舗 {
  // 受注余力があって、まだ受注していない店舗がいくつかあること
  some d: OrderDetail | d.requested_deliveries = none implies 
    (明細完受注可店舗在り[d] 
//and 明細完受注NG店舗在り[d]
)
  some o: Order | o.order_details.requested_deliveries = none implies 
    全品受注OK店舗在り[o]
}
/*-------------------------------------------------------------------------------------------*/

pred b_gte(v,v': Int) {
  vCheck[v] implies 1=1 else gte[v,v']
}
pred b_gt(v,v': Int) {
  vCheck[v] implies 1=1 else gt[v,v']
}
pred b_lte(v,v': Int) {
  vCheck[v] implies 1=2 else lte[v,v']
}
pred b_lt(v,v': Int) {
  vCheck[v] implies 1=2 else lt[v,v']
}
pred vCheck(v: Int) {lt[v,0]}


run {
  未決注文明細と受注余力有店舗
} for 6 but  5 Int
