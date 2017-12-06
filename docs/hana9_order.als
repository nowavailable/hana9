open hana9
module hana9_order
/*-------------------------------------------------------------------------------------------*/
pred b_gte(v,v': Int) {
  vCheck[v] implies eq[1,1] else gte[v,v']
}
pred b_gt(v,v': Int) {
  vCheck[v] implies eq[1,1] else gt[v,v']
}
pred b_lte(v,v': Int) {
  vCheck[v] implies eq[1,2] else lte[v,v']
}
pred b_lt(v,v': Int) {
  vCheck[v] implies eq[1,2] else lt[v,v']
}
pred vCheck(v: Int) {lt[v,0]}
/*-------------------------------------------------------------------------------------------*/
-- ビジネスロジック上自明な
fact {
  // quantity系としきい値系は、正の数。そしてなるべく小さく。
  all r: RuleForShip |
    pos[r.interval_day.val] && lte[r.interval_day.val, 4] &&
    pos[r.quantity_limit.val] && lte[r.quantity_limit.val, 6] &&
    pos[r.quantity_available.val] && lte[r.quantity_available.val, 6]
  all s: Shop | pos[s.delivery_limit_per_day.val] && lte[s.delivery_limit_per_day.val, 6]
  all d: OrderDetail | pos[d.quantity.val] && lte[d.quantity.val, 8] &&
    pos[d.expected_date.val]
  all r: RequestedDelivery | pos[r.quantity.val] && lte[r.quantity.val, 6]

  // 未決の注文明細の日付は、本日以降であること。
  all d: OrderDetail | eq[#(d<:requested_deliveries), 0] => gt[d.expected_date.val, Now.val]
  // 配達希望日は注文日より未来
  all o: Order |
    all e_date: o.order_details.expected_date | gt[e_date.val, o.ordered_at.val]
  // 取扱がある店が配達
  all r: RequestedDelivery |
    (r.shop.rule_for_ships<:merchandise:>r.order_detail.merchandise).Merchandise != none

  // 値の異なっていて欲しい、マスタ系レコード
  all c,c': City | c != c' => not eq[c.label.val, c'.label.val]
  all s,s': Shop | s != s' => not eq[s.label.val, s'.label.val] && not eq[s.code.val, s'.code.val]
  all m,m': Merchandise | m != m' => not eq[m.label.val, m'.label.val]
  // コードの一貫性
  all d: OrderDetail |
    let codVal = d.order.order_code.val |
    all req, req': d.requested_deliveries.order_code.val |
      req != req' => eq[req.order_code.val, req'.order_code.val]
        && eq[req.order_code.val, codVal]
  // 明細がすべて未決の注文もある。
  some o: Order | o.order_details.requested_deliveries = none
  // 部分的に明細が未決の注文は、無いものとする？あるいは許容？
  //one o: Order | not eq[#(o.order_details.requested_deliveries), #(o.order_details)]
}
-- 数量整合性
fact {
  // 数量のキャパシティに沿った受注がなされていること
  all req: RequestedDelivery |
    lte[req.quantity.val, QUANTITY_LIMIT_BY_REQ[req].val]
  // ひとつの注文明細に複数の配達指示がある場合、そのどちらかはRuleForShipのリミットに達している
  // また、配達指示の個数が注文明細の個数と合っていること
  all d: OrderDetail |
    (
      eq[#(d<:requested_deliveries), 1] implies //matchQuantity[d])
        all req: d.requested_deliveries | eq[d.quantity.val, req.quantity.val]
    ) && (
      b_gt[#(d<:requested_deliveries), 1] iff
        gt[d.quantity.val, 1]
        && (some req: d.requested_deliveries |
          eq[req.quantity.val, (QUANTITY_LIMIT_BY_REQ[req].val)])
        && (all req: d.requested_deliveries |
          lt[req.quantity.val, d.quantity.val])
        // ↓このsumが効いていれば、上の二つの条件は不要なのだが、
        // 　このようにすこしづつ絞り込まないと、sumが正しく動作しない？
        && eq[d.quantity.val, sum[d.requested_deliveries.quantity.val]]
    )
}
-- 配達可能地域
fact {
  all d: OrderDetail |
    // 配達可能地域定義に沿った受注がなされていること
    OrderDetail.(d<:requested_deliveries.shop) in CAN_DELIVERY_SHOPS[d]
}
-- 配達リソース整合性
fact {
  all s: Shop |
    all dateVal: Shop.(s<:requested_deliveries.order_detail.expected_date.val),
        lim: s.ship_limits, details: s.requested_deliveries.order_detail |
      let worksOnThatDay = (details<:expected_date):>(Boundary->dateVal & Boundary<:val).Int |
        eq[#(worksOnThatDay), s.delivery_limit_per_day.val]
        and
        lte[#(worksOnThatDay), #((lim<:expected_date):>(Boundary->dateVal & Boundary<:val).Int)]
}
/*-------------------------------------------------------------------------------------------*/
/*pred matchQuantity(d: OrderDetail) {
  eq[d.quantity.val,sum[d.requested_deliveries.quantity.val]]
}*/

// その日は既にふさがっている
pred theDayIsFull(date: Boundary, shop: Shop) {
  not eq[#(
    ((shop.ship_limits)<:expected_date):>((Boundary->(date.val) & Boundary<:val).Int)
  ), 0]
}
// 受注候補店舗のうち一軒でも、明細すべてに対して、全条件をクリアできていたら
pred canRecieveDetailAll(o: Order) {
  let candidates = o.order_details.merchandise.rule_for_ships.shop |
  some candidate_shop: candidates |
    all detail: o.order_details |
      let rule = (candidate_shop.rule_for_ships<:merchandise:>detail.merchandise).Merchandise |
      (rule != none)
      //明細完受注可
      && gte[QUANTITY_LIMIT[detail.expected_date, rule].val, detail.quantity.val]
      && candidate_shop in CAN_DELIVERY_SHOPS[detail]
      && candidate_shop in detail.merchandise.rule_for_ships.shop // candidate_shopは、"Orderで"束ねた群なのでさらに絞る
      && not theDayIsFull[detail.expected_date, candidate_shop]
}
// 明細完受注NG店舗在り
pred canRecieveDetailPartly(d: OrderDetail) {
  (some rule: d.merchandise.rule_for_ships |
      not gte[QUANTITY_LIMIT[d.expected_date, rule].val, d.quantity.val]
      and rule.shop in CAN_DELIVERY_SHOPS[d]
      and not theDayIsFull[d.expected_date, rule.shop]
  ) //and (
    //some rule: d.merchandise.rule_for_ships |
    //  gte[QUANTITY_LIMIT[d.expected_date, rule].val, d.quantity.val]
    //  and rule.shop not in CAN_DELIVERY_SHOPS[d]
    //  and not theDayIsFull[d.expected_date, rule.shop])
}
/*-------------------------------------------------------------------------------------------*/
//数量リミット
fun QUANTITY_LIMIT(date: Boundary, rule: RuleForShip) : Boundary {
  b_gte[date.val.minus[Now.val], rule.interval_day.val] implies
    rule.quantity_limit else rule.quantity_available
}
fun QUANTITY_LIMIT_BY_REQ (req: RequestedDelivery) : one Boundary {
  let rule = (req.shop.rule_for_ships<:merchandise:>req.order_detail.merchandise).Merchandise |
    QUANTITY_LIMIT[req.order_detail.expected_date, rule]
}
// そこにそれを配達が可能な店舗
fun CAN_DELIVERY_SHOPS (d: OrderDetail) : set Shop {
  CitiesShop.(((CitiesShop<:city:>d.city).City)<:shop)
}
/*-------------------------------------------------------------------------------------------*/
-- テスト上恣意的な
fact {
  // 出荷ルールの多様性
  all r,r': RuleForShip |
    r != r' => not eq[r.quantity_limit.val, r'.quantity_limit.val]
      && not eq[r.quantity_available.val, r'.quantity_available.val]
  // マージンの多様性
  all s,s': Shop | s != s' => not eq[s.mergin.val, s'.mergin.val]
  // 複数分担の配達指示
  some d: OrderDetail | b_gt[#(d<:requested_deliveries), 1]
  // 配達先のカーディナリティ
  gt[#(CitiesShop.city), 3]
  //
  gte[#(RequestedDelivery), 3]
}
/*-------------------------------------------------------------------------------------------*/
pred notYetDetailsAndShops {
  // 受注余力があって、まだ受注していない店舗がいくつかあること
  some o: Order | (o.order_details.requested_deliveries = none) &&
    (
      canRecieveDetailAll[o]
      //||
      //(some d: o.order_details | canRecieveDetailPartly[d])
    )
}
run {
  notYetDetailsAndShops
} for 8 but 3 ShipLimit, 3 Merchandise, 5 City,
6 Int, 31 seq
//5 Int, 15 seq
