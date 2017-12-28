open hana9_order

--
-- 受注余力があって、まだ受注していない店舗がいくつかある状態
--
pred allDetailOK {
  some o: Order | 
    (o.order_details.requested_deliveries = none) 
    && gt[#o.order_details, 1]
    && (o.order_details.merchandise.rule_for_ships.shop != none)
    && let candidates = o.order_details.merchandise.rule_for_ships.shop |
      /** 受注候補店舗が3つ以上ある状態を作る。
          同一制約下で、任意の数のatomインスタンスを確保する方策 */
      gt[#candidates,3]
      && all disj candidate1, candidate2, candidate3: candidates |
        canRecieveAllDetail[o,candidate1] 
        && canRecieveAllDetail[o,candidate2] 
        && canRecieveAllDetail[o,candidate3]
}
// run での sig の絞り込みは最小限に。また、
// 全体のscope数と大きく差のあるsig絞り込みを設定すると、正しく動作しないことがある。
// なおこのalsは alloy* (alloystar) での実行を前提としている。
run {
  allDetailOK
} for 8 but 3 ShipLimit, // 4 Merchandise, 5 City, 
1..20 Int, 20 seq
//5 Int, 15 seq
