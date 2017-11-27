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
      available_shops = Shop.eager_load(
          :cities, :rule_for_ships
        ).where(
          cities: {id: order_detail.city_id},
          rule_for_ships: {id: order_detail.merchandise_id}
        # 在庫による絞り込み
        ).where(
          # お届け希望日までの日数で出荷できるかどうか
          # ※指定された数量を満たせるかどうかは、別途クエリ外で判定
          "rule_for_ships.interval_day >= ?", days_remaining
        ).select(
          "*," +
          "rule_for_ships.quantity_limit AS quantity_limit," +
          "rule_for_ships.quantity_available AS quantity_available"
        # 稼働リソース残度による絞り込み
        ).where(
          ShipLimit.where(expected_date: order_detail.expected_date).exists.not
        ).joins(
          "LEFT OUTER JOIN (" +
            RequestDelivery.eager_load(:order_detail).
              select("requested_deliveries.shop_id, COUNT(requested_deliveries.shop_id) AS scheduled_count").
              where(order_detail: {expected_date: order_detail.expected_date}).
              group("requested_deliveries.shop_id").to_sql +
          ") AS scheduled ON scheduled.shop_id = shops.id"
        ).where("scheduled_count >= shops.delivery_limit_per_day").
        order(
          "(shops.delivery_limit_per_day - scheduled_count) DESC, shops.mergin DESC"
        )
        # 未永続化のOrderDetailを受理した結果、delivery_limit_per_day に達してしまう店が
        # あるかもしれない。それはこのクエリでは検知できないので別途検査する。

      # 結果をインスタンス変数に記録。
      if available_shops.blank?
        order_detail.is_available = false
      elsif
        # 受注候補加盟店の在庫すべて合わせても、お届け希望日までの日数で指定された数量を出荷できない場合
        available_shops.sum{|shop| shop.quantity_limit} < order_detail.quantity and
        available_shops.sum{|shop| shop.quantity_available} < order_detail.quantity
        order_detail.is_available = false
      else
        order_detail.is_available = true
      end
      context.candidate_shops.push(
        Context::Order::CandidateShop.new(
          order_detail, order_detail.is_available ? available_shops : []
        )
      )
    end
  end

  # order_detail.is_available が true であっても、
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
  #
  def check_risk
    raise("Order invalid.") if !context.order
    candidates = context.candidate_shops.select{|c| c.order_detail.is_available}
    return if candidates.empty?

    # Shopの、配達に関するリソースを表現する構造体のリスト。
    shop_resouces = context.candidate_shops.select{|c| c.shops}.
      flatten.uniq.map{|shop| Context::Order::ShopResource.new(shop: shop)}
    # 配達指示を仮想することで個数が取り崩されていく
    # 処理対象のOrderDetailを表現した構造体、のリスト。
    stacked_order_details = candidates.map{|c|
      Context::Order::StackedOrderDetail.new(order_detail: c.order_detail)}

    # 仮の配達指示をカウントして、稼働リミットに達する受注候補加盟店があるかどうか検査
    catch(:on_risk) do
      candidates.each do |candidate|
        catch(:order_detail_processed) do
          order_detail = candidate.order_detail
          current_order_detail = stacked_order_details.
              select{|a|a.order_detail.is_equive(order_detail)}.first
          # candidate.shops は、"配達リソースの余裕の大きい順"に並んでいる
          candidate.shops.each do|shop|
            current_shop_resouce = shop_resouces.select{|a| a.shop.id == shop.id}.first
            # この受注候補加盟店が、リソ−スを計算済みの店群からすでに消えていたらそれは
            if !current_shop_resouce
              context.order.on_risk = true
              throw :on_risk
            end
            # 配達指示を仮定したその結果リソ−スが無くなったら、リソ−スを計算済みの店群から取り除く
            if current_shop_resouce.capacity(order_detail.expected_date) ==
                current_shop_resouce.scheduled(order_detail.expected_date)
              shop_resouces.delete(current_shop_resouce)
            end
            # 加盟店ごとの扱い数量
            actual_quantity = current_shop_resouce.actual_quantity(order_detail)
            # 数量（OrderDetail.quantityそのままではない）
            amount = current_order_detail.amount
            # この加盟店ひとつで、ひとつの注文明細の出荷をまかなえるなら、次の明細へ。
            # そうでないなら、出荷できる数だけ消化して次の店舗へ。
            if actual_quantity >= amount
              current_order_detail.amount(amount)
              throw :order_detail_processed
            else
              current_order_detail.amount(actual_quantity)
            end
          end
        end
      end
    end
  end
end