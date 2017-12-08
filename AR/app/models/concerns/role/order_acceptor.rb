module Role::OrderAcceptor
  include IOrderManipulator
  include Context::ContextAccessor

  # TODO: 注入された先の宿主オブジェクトが適正かどうかチェック。
  # ・order は、お届け希望日と、配送先住所（市区町村ID？）と、数量を持ち、それにアクセスできること。
  # など。
  def self.extended(order)

  end

  #----------------------------------------------------------------------------
  # 注文に含まれる注文明細のうち、成立可能な明細行は、is_available を true に、
  # そうでないものは false にする。
  #
  # NOTICE: 一日で商品Aを10点出荷できる加盟店は、n日後であれば同商品を10✕n点出荷できる計算になる。
  # が、商品が生花であることにかんがみて、n は常に、rule_for_shops.interval_day と等しいものとする。
  # つまり n は常に最小値をとり、それ以上は想定しない。
  #
  # NOTICE: 未永続化のOrderDetailを受理した結果、delivery_limit_per_day に達してしまう店が
  # あるかもしれない。それはこのクエリでは検知できないので別途 check_risk() で検査する。
  #----------------------------------------------------------------------------
  def build_acceptable_list
    raise("Order invalid.") if !context.order
    #
    # 注文明細毎に、それを受けられる候補Shopのリストを保持
    #
    aliase = "shop_resource_delivery"
    context.order.order_details.each do |order_detail|
      next if order_detail.requested_deliveries.length > 0  # 部分的に明細が未決の注文、というものがあれば
      days_remaining = (order_detail.expected_date - Date.today).to_i
      query =<<STR
        SELECT shops.*, cities_shops.*, rule_for_ships.*,
          CASE WHEN #{aliase}.#{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT} IS NULL 
          THEN 0 ELSE #{aliase}.#{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT} END 
            AS #{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT},
          (CASE WHEN rule_for_ships.interval_day <= #{days_remaining} 
            THEN rule_for_ships.quantity_limit
            ELSE rule_for_ships.quantity_available 
            END - #{order_detail.quantity}) AS #{Context::Order::FIELD_NAME_ACTUAL_QUANTITY}
        FROM shops
        INNER JOIN cities_shops ON cities_shops.shop_id = shops.id
        INNER JOIN rule_for_ships ON rule_for_ships.shop_id = shops.id
        #{
          # 配達の稼働リソース残度による絞り込み条件。ここでは商品は問うてはいけない。
          }
        LEFT OUTER JOIN (
          SELECT shops.id AS shop_id, shops.delivery_limit_per_day, 
            CASE WHEN requested_deliveries.id IS NULL 
            THEN 0 ELSE  COUNT(requested_deliveries.id) END 
              AS #{Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT}
          FROM shops
          LEFT OUTER JOIN requested_deliveries ON requested_deliveries.shop_id = shops.id
          LEFT OUTER JOIN order_details ON order_details.id = requested_deliveries.order_detail_id
          WHERE order_details.expected_date = :expected_date
          GROUP BY requested_deliveries.shop_id
            HAVING COUNT(requested_deliveries.shop_id) < shops.delivery_limit_per_day
        ) AS #{aliase} ON #{aliase}.shop_id = shops.id
        #{
          # 在庫による絞り込み条件。受注でき得る加盟店群の、捌ける数量をすべて合わせても対応できない量でないかどうかをみている。
          }
        WHERE EXISTS (
          SELECT rule_for_ships.merchandise_id
          FROM rule_for_ships
          LEFT OUTER JOIN cities_shops ON cities_shops.shop_id = rule_for_ships.shop_id
          WHERE cities_shops.city_id = :city_id
          AND rule_for_ships.merchandise_id = :merchandise_id
          GROUP BY rule_for_ships.merchandise_id
            HAVING SUM(CASE WHEN rule_for_ships.interval_day <= #{days_remaining} 
              THEN rule_for_ships.quantity_limit
              ELSE rule_for_ships.quantity_available 
              END) >= #{order_detail.quantity}
        )
        AND cities_shops.city_id = :city_id
        AND rule_for_ships.merchandise_id = :merchandise_id
        ORDER BY shops.mergin DESC
STR
      available_shops = Shop.find_by_sql(
        [query,
        {city_id: order_detail.city_id,
          merchandise_id: order_detail.merchandise_id,
          expected_date: order_detail.expected_date
        }])
      # 結果をインスタンス変数に記録。
      order_detail.is_available = !available_shops.blank?
      context.candidate_shops.push(
        Context::Order::CandidateShop.new(
          order_detail, order_detail.is_available ? available_shops : []))
    end
  end

  #----------------------------------------------------------------------------
  # NOTICE: order_detail.is_available が true であっても、
  # 1.この注文明細のいずれか〜すべてを受けると、（数量でなく）配達に関する稼働リミット
  #   を超えてしまう店舗があるかもしれない。それは要注意デ−タとしてマ−ク。
  # 2.要注意デ−タが混じっていても、組み合わせ次第では注文をすべて受けられる可能性はある。
  #   例えば、明細（=商品）1を、店A、Bのうち、Aに割り振るようシミュレートしたが、
  #   その結果、店Aが稼働リミットに達したとする。その場合、別な明細（=商品）2が、店Aにしか
  #   引き受けられない品目であったとしも、引き受けられない。しかし、明細（=商品）1を店Bに
  #   割り振り直せば、明細（=商品）2を店Aが引き受けることが出来るかもしれない。
  #   これは本来、制約充足問題として解かなければいけない。
  #
  # FIXME: ここでは、上記のうち 1.のみをおこなうに留めている。
  #        注文明細あたりの受注候補加盟店は、余裕の大きい順に並べ替えて、シミュレートする。
  #----------------------------------------------------------------------------
  def check_risk
    raise("Order invalid.") if !context.order
    candidates = context.candidate_shops.select{|c| c.order_detail.is_available}
    return if candidates.empty?

    # Shopの、配達に関するリソースを表現する構造体のリスト。
    shop_delivery_resouces = context.candidate_shops.map{|c| c.shops}.
      flatten.uniq.map{|shop| Context::Order::ShopDeliveryResource.new(shop: shop)}
    # 配達指示を仮想することで個数が取り崩されていく
    # 処理対象のOrderDetailを表現した構造体、のリスト。
    stacked_order_details = candidates.map{|c|
      Context::Order::StackedOrderDetail.new(order_detail: c.order_detail)}

    # 仮の配達指示をカウントして、稼働リミットに達する受注候補加盟店があるかどうか検査
    catch(:on_risk) do
      candidates.each do |candidate|
        catch(:order_detail_processed) do
          current_order_detail = stacked_order_details.
            select {|a| a.order_detail.is_equive(candidate.order_detail)}.first
          # candidate.shops は、"配達リソースの余裕の大きい順"に並んでいる
          candidate.shops.each do |shop|
            current_shop = shop_delivery_resouces.select {|a| a.shop.id == shop.id}.first
            # この受注候補加盟店が、リソ−スを計算済みの店群からすでに消えていたらそれは
            if !current_shop
              context.order.on_risk = true
              throw :on_risk
            end
            # 配達指示を仮定したその結果リソ−スが無くなったら、リソ−スを計算済みの店群から取り除く
            if current_shop.shop.delivery_limit_per_day.to_i -
              current_shop.shop.send(Context::Order::FIELD_NAME_SCHEDULED_DELIVERY_COUNT) -
              current_shop.new_scheduled_count(candidate.order_detail.expected_date) == 0
              shop_delivery_resouces.delete(current_shop)
            end
            # この加盟店ひとつで、ひとつの注文明細の出荷をまかなえるなら、次の明細へ。
            # そうでないなら、出荷できる数だけ消化して次の店舗へ。
            next_detail =
              shop.send(Context::Order::FIELD_NAME_ACTUAL_QUANTITY) == candidate.order_detail.quantity
            current_order_detail.amount(shop.send(Context::Order::FIELD_NAME_ACTUAL_QUANTITY))
            throw :order_detail_processed if next_detail
          end
        end
      end
    end
  end
end