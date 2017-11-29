module Role::DeliveryProposer
  include Context::ContextAccessor

  # TODO: 注入された先の宿主オブジェクトが適正かどうかチェック。
  # ・order は、お届け希望日と、配送先住所（市区町村ID？）と、数量を持ち、それにアクセスできること。
  # など。
  def self.extended(order)

  end

  # 注文に含まれる明細をすべて且つ全数量受注できる店舗のリストを
  # 手数料率の高い順に並べて返す
  def shops_fullfilled_profitable
    detail_all_possible_shops =
      shops_fullfilled(context.order.order_details)
    context.shops_fullfilled_profitable =
      detail_all_possible_shops.select {|e| e.count == context.order.order_details.length}.
        map {|e| e.shop}.
        sort_by {|shop| shop.margin}.
        reverse
  end

  # 注文に含まれる明細をすべて且つ全数量受注できる店舗のリストを
  # 稼働の小さい順に並べて返す
  def shops_fullfilled_leveled
    detail_all_possible_shops =
      shops_fullfilled(context.order.order_details)
    context.shops_fullfilled_leveled =
      detail_all_possible_shops.select {|e| e.count == context.order.order_details.length}.
        map {|e| e.shop}.
        sort_by {|shop|
          shop.delivery_limit_per_day -
            shop.send(Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT)
        }.reverse
  end

  # 注文に含まれる明細の一部だけを受注できる店舗のリストを
  # 商品（注文明細）ごとに、手数料率の高い順に並べて返す
  def shops_partial_profitable
    # available_shops =
    #   context.candidate_shops.select{|c| c.shops}

    # 注文に含まれる明細をすべて且つ全数量受注できる店舗があるなら、
    # それらの店舗はは、このメソッドのの処理結果リストから
    # 除く必要があるかも知れない。
    if context().shops_fullfilled_profitable() != []
    end
    shops = []
    return shops
  end

  # 注文に含まれる明細の一部だけを受注できる店舗のリストを
  # 商品（注文明細）ごとに、稼働の小さい順に並べて返す
  def shops_partial_leveled
    # available_shops =
    #   context.candidate_shops.select{|c| c.shops}

    # 注文に含まれる明細をすべて且つ全数量受注できる店舗があるなら、
    # それらの店舗はは、このメソッドのの処理結果リストから
    # 除く必要があるかも知れない。
    if context().shops_fullfilled_leveled() != []
    end
    shops = []
    return shops
  end

  def shops_fullfilled(order_details)
    _DetailAllPossibleShop = Struct.new(:shop, :count)
    detail_all_possible_shops = []
    order_details.each do |order_detail|
      detail_all_possible_query_arel(order_detail).all.select {|c| c.shops}.each do |shop|
        if !detail_all_possible_shops.map {|e| e.shop.id}.include?(shop.id)
          detail_all_possible_shops.push(_DetailAllPossibleShop.new(shop, 0))
        end
        detail_all_possible_shops.select {|e| e.shop.id == shop.id}.first.count += 1
        # detail_all_possible_shops.select {|e| e.shop.id == shop.id}.first.order_detail = order_detail
      end
    end
    return detail_all_possible_shops
  end
  private :shops_fullfilled

  def detail_all_possible_query_arel(order_detail)
    days_remaining = (order_detail.expected_date - Date.today).to_i
    query =<<STR
      SELECT *,
        #{aliase}.#{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT}  
          AS #{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT},
        (IF rule_for_ships.interval_day >= #{days_remaining} 
          THEN rule_for_ships.quantity_limit
          ELSE rule_for_ships.quantity_available 
          END - #{order_detail.quantity}) AS #{Context::Order::FIELD_NAME_ACTUAL_QUANTITY}
      FROM shops
      INNER JOIN cities_shops ON cities_shops.shop_id = shops.id
      INNER JOIN rule_for_ships ON rule_for_ships.shop_id = shops.id
      INNER JOIN (
        SELECT shops.id AS shop_id, 
          COUNT(requested_deliveries.id) AS #{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT}
        FROM shops
        LEFT OUTER JOIN requested_deliveries ON requested_deliveries.shop_id = shops.id
        LEFT OUTER JOIN order_details ON order_details.id = requested_deliveries.order_detail_id
        GROUP BY requested_deliveries.shop_id
          HAVING COUNT(requested_deliveries.shop_id) < shops.delivery_limit_per_day
        WHERE order_details.expected_date = :expected_date
      ) AS #{aliase} ON #{aliase}.shop_id = shops.shop_id
      WHERE cities_shops.city_id = :city_id
      AND rule_for_ships.merchandise_id = :merchandise_id
      AND (IF rule_for_ships.interval_day >= #{days_remaining} 
        THEN rule_for_ships.quantity_limit
        ELSE rule_for_ships.quantity_available 
        END) >= #{order_detail.quantity}
STR
    Shop.find_by_sql(
      query,
      {city_id: order_detail.city_id,
        merchandise_id: order_detail.merchandise_id,
        expected_date: order_detail.expected_date
      })
  end
  private :detail_all_possible_query_arel

end