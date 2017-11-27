#
# "ユーザーが、顧客として、注文をしたい。"
#
class Context::Order
  attr_accessor :order, :candidate_shops

  # 注文を受けることのできる、候補の加盟店群。注文明細毎にリストで保持。
  CandidateShop = Struct.new(:order_detail, :shops)

  # Shopの、配達に関するリソースを表現。リストにして使用。
  class ShopResource
    attr_accessor :shop
    def initialize(h)
      @shop = h[:shop] if h[:shop]
      @delivery_capacity = {}
      @scheduled_count = {}
      @actual_quantity = {}
    end
    def delivery_capacity(expected_date)
      # 規定された日毎のlimit - すでに消費されている日毎のlimit
      @delivery_capacity[expected_date.to_s] ||=
        @shop.delivery_limit_per_day -
          RequestDelivery.eager_load(:order_detail).
            select("COUNT(requested_deliveries.shop_id) AS cnt").
            where(
              order_detail: {expected_date: expected_date},
              shop_id: @shop.id
            ).group("requested_deliveries.shop_id").
            where("COUNT(requested_deliveries.shop_id) >= shops.delivery_limit_per_day").
            first.cnt.to_i
    end
    def scheduled_count(expected_date)
      # （仮に）スケジュ−ルされた配達指示の、日別の数を保持
      @scheduled_count[expected_date.to_s] =
        (@scheduled_count[expected_date.to_s] || 0) + 1
    end
    def actual_quantity(order_detail)
      # 加盟店ごとの実際の出荷可能最大数量
      if !@actual_quantity[order_detail.identifier]
        rule_for_ship =
          self.shop.rule_for_ships.where(
            merchandise_id: order_detail.merchandise_id
          ).first
        days_remaining = (order_detail.expected_date - Date.today).to_i
        @actual_quantity[order_detail.identifier] =
          (rule_for_ship.interval_day >= days_remaining ?
            rule_for_ship.quantity_limit : rule_for_ship.quantity_available)
      end
      return @actual_quantity[order_detail.identifier]
    end
  end

  # 配達指示を仮定することで取り崩されていく注文明細を表現。リストにして使用。
  class StackedOrderDetail
    attr_accessor :order_detail
    def initialize(h)
      @order_detail = h[:order_detail] if h[:order_detail]
    end
    def amount(num=nil)
      @amount = self.order_detail.quantity if !@amount
      @amount - num if num
      return @amount
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

  def append_order_detail(merchandise, city, quantity, expected_date)
    if !@order
      # 発番するRole
      @order.extend Role::OrderNumberGenerator
      @order = Order.new
      @order.build_psuedo_order_code
    elsif !@order.class.singleton_class.include?(Role::OrderNumberGenerator)
      @order.extend Role::OrderNumberGenerator
    end
    order_detail = @order.order_details.build(
      merchandise_id: merchandise.id,
      city_id: city.id,
      quantity: quantity,
      expected_date: expected_date,
    )
    @order.build_seq_code(order_detail)
  end

  def place_order

  end

  def display_form

  end

  def validate

  end

end