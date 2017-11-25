module Role::OrderAcceptor
  include IOrderCanceler

  # TODO: 注入された先の宿主オブジェクトが適正かどうかチェック。
  # ・order は、お届け希望日と、配送先住所（市区町村ID？）と、数量を持ち、それにアクセスできること。
  # など。
  def self.extended(order)

  end

  # 注文に含まれる注文明細のうち、
  # 成立可能な行には、is_available を true に、
  # そうでないものは false にする。
  def build_acceptable_list
    raise("Order invalid.") if !context.order

    # 注文明細毎に、それを受けられる候補Shopのリストを保持
    context.order.order_details.each do |order_detail|
      days_remaining = (order_detail.expected_date - Date.today).to_i
      available_shops = Shop.includes(
        :cities,
        :rule_for_ships
      ).where(
        cities: {id: order_detail.city_id},
        rule_for_ships: {id: order_detail.merchandise_id}
      # 在庫による絞り込み
      ).where(
        # お届け希望日までの日数で指定された数量を出荷できるかどうか
        "(rule_for_ships.interval_day >= :days_remaining AND " +
          "rule_for_ships.quantity_limit >= :quantity) OR " +
          # または店頭在庫数が指定された数量を満たせるかどうか
          "(rule_for_ships.quantity_available >= :quantity)",
        {days_remaining: days_remaining, quantity: order_detail.quantity}
      # 稼働による絞り込み
      ).where(
        ShipLimit.where(expected_date: order_detail.expected_date).exists.not.
        # 出荷のための制約が厳格になりすぎるのを敢えて避けるのであれば、
        # ↓以下の絞り込みサブクエリは無くてもよいかも。
        or(
          RequestDelivery.eager_load(:order_detail, :shop).
            select("COUNT(requested_deliveries.shop_id)").
            where(
              order_detail: {expected_date: order_detail.expected_date}
            ).group(
              "requested_deliveries.shop_id"
            ).where(
              "COUNT(requested_deliveries.shop_id) >= shops.delivery_limit_per_day"
            ).exists.not
        )
        # 未永続化のOrderDetailを受理した結果、delivery_limit_per_day に達してしまう店が
        # あるかもしれない。それはこのクエリでは検知できないので別途検査する。
      )
      # 結果をインスタンス変数に記録。
      order_detail.is_available = !available_shops.blank?
      context.candidate_shops.push(
        Context::Order::CandidateShop.new(order_detail, available_shops)
      )
    end
  end

  # order_detail.is_available が true であっても、
  # 1.この注文明細のいずれか〜すべてを受けると、稼働リミットを超えてしまう店舗が
  #   あるかもしれない。それは要注意デ−タとしてマ−ク。
  # 2.要注意デ−タが混じっていても、組み合わせ次第では注文をすべて受けられる可能性はある。
  #   それを、制約充足問題として解いて、受注可能であることを証明する必要がある。
  #
  # FIXME: ここでは、上記のうち 1.のみをおこなうに留めている。
  #
  def build_risk_list
    raise("Order invalid.") if !context.order
    # order_detail.is_available がすべて false ならリタ−ン。
    return if
      context.order.order_details.select{|order_detail|
        order_detail.is_available != false
      }.empty?

    # 候補ショップ毎に、受注するかもしれない注文明細の
    # 受注を仮定し、稼働リミットに達するかどうか見る。

    # そのための変数。candidate_shops を転置した構造の変数を作成。
    _CandidateOrderDetail = Struct.new(:shop, :order_details)
    candidate_order_details = []
    context.candidate_shops.each do |candidate_shop|
      candidate_shop.shops.each do|shop|
        # リスト内でこの項目の値はユニ−クに。
        if !candidate_order_details.map{|c|c.shop.id}.include?(shop.id)
          candidate_order_details.push(_CandidateOrderDetail.new(shop))
        end
        candidate_order_details.select{|c| c.shop.id = shop.id}.
          first.order_details.push(candidate_shop.order_detail)
      end
    end
    # 1.の処理の実体。
    candidate_order_details.each_with_index do |candidate_order_detail, idx|
      if !candidate_order_detail.shop.can_recieve_order_safely?(candidate_order_detail.order_details)
        candidate_order_detail.order_details.each do |order_detail|
          # 結果をインスタンス変数に記録。
          context.order.order_details.select {|o_detail|
            o_detail.is_equive(order_detail)
          }.first.
            on_risk = true
        end
      end
    end
  end

end