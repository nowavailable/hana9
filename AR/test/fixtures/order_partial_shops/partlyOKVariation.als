open hana9_order

--
-- 明細を完受注できる店舗が無い。しかし候補店舗のリソ−スをすべて足せば、その注文明細を受けられる状態
--
pred partlyOKVariation {
  some o: Order | 
    (o.order_details.requested_deliveries = none) 
    && gt[#o.order_details, 1]
    // 各々異なる商品であること
    && eq[#o.order_details.merchandise, #o.order_details]
    && (o.order_details.merchandise.rule_for_ships != none)
    && (
      let candidate_shops = o.order_details.merchandise.rule_for_ships.shop |
      eq[#candidate_shops, 3]
      && (all detail: o.order_details |
        // 単独ではいち明細さえも受注できない。しかし取り扱いはある。
        (all cshop: candidate_shops |
          canNotRecieveDetailComplete[o, cshop, detail])
        // 候補店舗のリソ−スをすべて足せば、その注文明細を受けられる
        && (all disj cshop1, cshop2, cshop3: candidate_shops |
          gte[
            sum[
              QUANTITY_LIMIT[detail.expected_date, (cshop1.rule_for_ships<:merchandise:>detail.merchandise).Merchandise].val 
              + QUANTITY_LIMIT[detail.expected_date, (cshop2.rule_for_ships<:merchandise:>detail.merchandise).Merchandise].val
              + QUANTITY_LIMIT[detail.expected_date, (cshop3.rule_for_ships<:merchandise:>detail.merchandise).Merchandise].val
            ], 
            detail.quantity.val
          ]
        )
      )
    )
}

// run での sig の絞り込みは最小限に。また、
// 全体のscope数と大きく差のあるsig絞り込みを設定すると、正しく動作しないことがある。
// なおこのalsは alloy* (alloystar) での実行を前提としている。
run {
  partlyOKVariation
} for 8 but 3 ShipLimit, // 4 Merchandise, 5 City, 
// シーケンス利用下では、Intはゼロを含むことが必須
0..19 Int, 19 seq
//5 Int, 15 seq
