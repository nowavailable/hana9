module Role::DeliveryProposer
  include Context::ContextAccessor

  # TODO: 注入された先の宿主オブジェクトが適正かどうかチェック。
  # ・order は、お届け希望日と、配送先住所（市区町村ID？）と、数量を持ち、それにアクセスできること。
  # など。
  def self.extended(order)

  end

  #----------------------------------------------------------------------------
  # 注文に含まれる明細をすべて且つ全数量受注できる店舗のリストを
  # 手数料率の高い順に並べて保管する
  #----------------------------------------------------------------------------
  def shops_fullfilled_profitable
    context.shops_fullfilled_profitable =
      shops_fullfilled(context.order).
        sort_by {|shop| shop.mergin.to_i}.
        reverse
  end
  #----------------------------------------------------------------------------
  # 注文に含まれる明細をすべて且つ全数量受注できる店舗のリストを
  # 稼働の小さい順に並べて保管する
  #----------------------------------------------------------------------------
  def shops_fullfilled_leveled
    context.shops_fullfilled_leveled =
      shops_fullfilled(context.order).
        sort_by {|shop|
          shop.delivery_limit_per_day.to_i -
            shop.send(Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT)
        }.reverse
  end
  #----------------------------------------------------------------------------
  # 注文に含まれる明細の一部だけを受注できる店舗のリストを
  # 商品（注文明細）ごとに、手数料率の高い順に並べて保管する
  #----------------------------------------------------------------------------
  def shops_partial_profitable
    # 注文に含まれる明細をすべて且つ全数量受注できる店舗があるなら、
    # それらの店舗はは、このメソッドのの処理結果リストから
    # 除く必要があるかも知れない。
    context.candidate_shops.each do |candidate_shop|
      if context.shops_fullfilled_profitable != []
        refined_shops =
          candidate_shop.shops.select{|shop|
            !context.shops_fullfilled_profitable.map{|e| e.id}.include?(shop.id)}
      end
      next if refined_shops.is_a?(Array) and refined_shops.empty?
      refined_shops =
        (refined_shops or candidate_shop.shops).sort_by{|shop| shop.mergin}.reverse
      context.shops_partial_profitable.push(
        Context::RequestDelivery::CandidateShop.new(candidate_shop.order_detail, refined_shops))
    end
    context.shops_partial_profitable
  end
  #----------------------------------------------------------------------------
  # 注文に含まれる明細の一部だけを受注できる店舗のリストを
  # 商品（注文明細）ごとに、稼働の小さい順に並べて保管する
  #----------------------------------------------------------------------------
  def shops_partial_leveled
    # 注文に含まれる明細をすべて且つ全数量受注できる店舗があるなら、
    # それらの店舗はは、このメソッドのの処理結果リストから
    # 除く必要があるかも知れない。
    context.candidate_shops.each do |candidate_shop|
      if context.shops_fullfilled_leveled != []
        refined_shops =
          candidate_shop.shops.select{|shop|
            !context.shops_fullfilled_leveled.map{|e| e.id}.include?(shop.id)}
      end
      next if refined_shops.is_a?(Array) and refined_shops.empty?
      refined_shops =
        (refined_shops or candidate_shop.shops).sort_by{|shop|
          shop.delivery_limit_per_day.to_i -
            shop.send(Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT)
        }.reverse
      context.shops_partial_leveled.push(
        Context::RequestDelivery::CandidateShop.new(candidate_shop.order_detail, refined_shops))
    end
    context.shops_partial_leveled
  end

  #
  # ある注文すべての内容を、一軒ですべてまかなえる加盟店のリストを返す
  #
  def shops_fullfilled(order)
    _DetailAllPossibleShop = Struct.new(:shop, :count)
    detail_all_possible_shops = []
    order.order_details.each do |order_detail|
      next if order_detail.requested_deliveries.length > 0  # 部分的に明細が未決の注文、というものがあれば
      detail_all_possible_query_arel(order_detail).each do |shop|
        if !detail_all_possible_shops.map {|e| e.shop.id}.include?(shop.id)
          detail_all_possible_shops.push(_DetailAllPossibleShop.new(shop, 0))
        end
        detail_all_possible_shops.select {|e| e.shop.id == shop.id}.first.count += 1
      end
    end
    detail_all_possible_shops.select {|e| e.count == order.order_details.length}.
      map {|e| e.shop}
  end
  private :shops_fullfilled

  #
  # ある注文明細の内容を、一軒ですべてまかなえる加盟店のリストを返す
  #
  def detail_all_possible_query_arel(order_detail)
    aliase = "shop_resource_delivery"
    days_remaining = (order_detail.expected_date - Date.today).to_i
    query =<<STR
      SELECT shops.*, 
        CASE WHEN #{aliase}.#{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT} IS NULL  
          THEN 0 ELSE #{aliase}.#{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT} 
          END AS #{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT},
        (CASE WHEN rule_for_ships.interval_day <= #{days_remaining} 
          THEN rule_for_ships.quantity_limit
          ELSE rule_for_ships.quantity_available 
          END - #{order_detail.quantity}) AS #{Context::Order::FIELD_NAME_ACTUAL_QUANTITY}
      FROM shops
      INNER JOIN cities_shops ON cities_shops.shop_id = shops.id
      INNER JOIN rule_for_ships ON rule_for_ships.shop_id = shops.id
      LEFT OUTER JOIN ship_limits ON ship_limits.shop_id = shops.id AND ship_limits.expected_date = :expected_date
      LEFT OUTER JOIN (
        SELECT shops.id AS shop_id, shops.delivery_limit_per_day,
        CASE WHEN requested_deliveries.id IS NULL 
        THEN 0 ELSE COUNT(requested_deliveries.id) END 
          AS #{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT}
        FROM shops
        LEFT OUTER JOIN requested_deliveries ON requested_deliveries.shop_id = shops.id
        LEFT OUTER JOIN order_details ON order_details.id = requested_deliveries.order_detail_id
        WHERE order_details.expected_date = :expected_date
        GROUP BY requested_deliveries.shop_id
          HAVING COUNT(requested_deliveries.shop_id) < shops.delivery_limit_per_day
      ) AS #{aliase} ON #{aliase}.shop_id = shops.id
      WHERE cities_shops.city_id = :city_id
      AND ship_limits.expected_date IS NULL
      AND rule_for_ships.merchandise_id = :merchandise_id
      AND (CASE WHEN rule_for_ships.interval_day <= #{days_remaining} 
        THEN rule_for_ships.quantity_limit
        ELSE rule_for_ships.quantity_available 
        END) >= #{order_detail.quantity}
STR
    Shop.find_by_sql(
      [query,
      {city_id: order_detail.city_id,
        merchandise_id: order_detail.merchandise_id,
        expected_date: order_detail.expected_date
      }])
  end
  private :detail_all_possible_query_arel

end