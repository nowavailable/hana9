#
# "ユーザーが、顧客として、注文をしたい。"
#
class Context::Order
  attr_accessor :order, :candidate_shops

  # 注文を受けることのできる、候補の加盟店群。注文明細毎にリストで保持。
  CandidateShop = Struct.new(:order_detail, :shops)

  # Shopの、配達に関するリソースを表現。リストにして使用。
  class ShopResource
    attr_accessor :shop, :limit_remaining, :scheduled, :actual_quantity_limit
    def limit_remaining(expected_date)
      # 規定された日毎のlimit - すでに消費されている日毎のlimit
      @limit_remaining[expected_date.to_s] ||=
        @shop.delivery_limit_per_day -
          RequestDelivery.eager_load(:order_detail).
            select("COUNT(requested_deliveries.shop_id)").
            where(
              order_detail: {expected_date: expected_date},
              shop_id: @shop.id
            ).group(
              "requested_deliveries.shop_id"
            ).where(
              "COUNT(requested_deliveries.shop_id) >= shops.delivery_limit_per_day"
            ).length
      return @limit_remaining[expected_date.to_s]
    end
    def actual_quantity_limit(order_detail)
      # 加盟店ごとの実際の出荷可能最大数量
      if !@actual_quantity_limit[order_detail.identifier]
        rule_for_ship =
          self.shop.rule_for_ships.where(
            merchandise_id: order_detail.merchandise_id
          ).first
        days_remaining = (order_detail.expected_date - Date.today).to_i
        @actual_quantity_limit[order_detail.identifier] =
          (rule_for_ship.interval_day >= days_remaining ?
            rule_for_ship.quantity_limit : rule_for_ship.quantity_available)
      end
      return @actual_quantity_limit[order_detail.identifier]
    end
    def scheduled(expected_date)
      # （仮に）スケジュ−ルされた配達指示の、日別の数を保持
      @scheduled[expected_date.to_s] = (@scheduled[expected_date.to_s] || 0) + 1
      return @scheduled[expected_date.to_s]
    end
  end

  # 配達指示を仮定することで取り崩されていく注文明細を表現。リストにして使用。
  class StackedOrderDetail
    attr_accessor :order_detail, :quantity_left
    def quantity_left(num=nil)
      @quantity_left = self.order_detail.quantity if !@quantity_left
      @quantity_left - num if num
      return @quantity_left
    end
  end

  # ある注文を、成立させられるかどうか判定する。
  def accept_check
    raise("Order invalid.") if !@order
    @candidate_shops = []

    execute_in_context do
      @order.extend Role::OrderAcceptor
      # 不成立の注文明細の有無を検査
      @order.build_acceptable_list
      # （加盟店の稼働リミットのために）
      # 成立しない危険がある注文明細の有無を検査
      @order.check_risk
    end

    # 不成立の注文明細

    # 成立しない危険がある注文明細

  end

  def append_order(merchandise, city, quantity, expected_date)
    if !@order
      @order = Order.new
      @order.build_psuedo_order_code
    end
    len = @order.order_details.length
    @order.order_details.build(
      merchandise_id: merchandise.id,
      city_id: city.id,
      quantity: quantity,
      expected_date: expected_date,
    ).build_seq_code
  end

  def place_order

  end

  def display_form

  end

  def validate

  end
end