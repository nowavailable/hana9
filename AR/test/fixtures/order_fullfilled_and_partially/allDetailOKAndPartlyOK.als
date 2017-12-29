open hana9_order

--
-- 注文完受注可能店舗と、明細のみ完受注可能店舗の混在する状態
--
pred allOKAndPartlyOK {
  some o: Order | 
    (o.order_details.requested_deliveries = none) 
    && (o.order_details.merchandise.rule_for_ships != none)
    // ここがキモ。エイリアスと結び込み。
    && (CandidateShop.shops[Int] = o.order_details.merchandise.rule_for_ships.shop)
    && eq[#CandidateShop.shops, 3]
    && lte[#o.order_details, 3]
    // 注文完受注可能店舗
    && canRecieveAllDetail[o, CandidateShop.shops.subseq[0,0][Int]] 
    // 明細のみ完受注可能店舗
    && (some detail: o.order_details |
      canRecieveDetailComplete[o, CandidateShop.shops.subseq[1,1][Int], detail])
    && not canRecieveAllDetail[o, CandidateShop.shops.subseq[1,1][Int]] 
    && (some detail: o.order_details |
      canRecieveDetailComplete[o, CandidateShop.shops.subseq[2,2][Int], detail])
    && not canRecieveAllDetail[o, CandidateShop.shops.subseq[2,2][Int]] 
}

/** エイリアス用途のsig。
    atomインスタンスを指定して、別々の制約を与えるために。 */
sig CandidateShop { shops: seq Shop}
fact { 
  // FIXME: 上記のseq、放っとくと、シーケンス（Int）とShopが1:nになったり、
  // 同じShopが何度も出現してしまったりするので
  // ・インデックスがユニ−クであること→要素数とインデックス数とが等しければそうなる。
  // ・要素が（このフィ−ルド全体として）ユニ−クであること
  // を制約づける必要がある。もっとよい書き方は無いか。
  eq[#CandidateShop.shops.inds, #CandidateShop.shops.elems] 
  && eq[#CandidateShop.shops, #CandidateShop.shops.inds]
}

// run での sig の絞り込みは最小限に。また、
// 全体のscope数と大きく差のあるsig絞り込みを設定すると、正しく動作しないことがある。
// なおこのalsは alloy* (alloystar) での実行を前提としている。
run {
  allOKAndPartlyOK
} for 8 but 3 ShipLimit, // 4 Merchandise, 5 City, 
// シーケンス利用下では、Intはゼロを含むことが必須
0..19 Int, 19 seq
//5 Int, 15 seq
