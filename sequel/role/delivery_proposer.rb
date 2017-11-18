module DeliveryProposer
  attr_accessor :order
  # 注入された先の宿主オブジェクトが適正かどうかチェック。
  # ・order は、お届け希望日と、配送先住所（市区町村ID？）と、数量を持ち、それにアクセスできること。
  # など。
  def self.extended(order)

  end

  # 注文に含まれる明細をすべて受注できる店舗のリストを
  # 手数料率の高い順に並べて返す
  def fullfilled_shops_profitable
    shops = []
    return shops
  end
  # 注文に含まれる明細をすべて受注できる店舗のリストを
  # 稼働の小さい順に並べて返す
  def fullfilled_shops_leveled
    shops = []
    return shops
  end
  # 注文に含まれる明細の一部だけを受注できる店舗のリストを
  # 商品ごとに。手数料率の高い順に並べて返す
  def partial_shops_profitable
    shops = []
    return shops
  end
  # 注文に含まれる明細の一部だけを受注できる店舗のリストを
  # 商品ごとに、稼働の小さい順に並べて返す
  def partial_shops_leveled
    shops = []
    return shops
  end
end