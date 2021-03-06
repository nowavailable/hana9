#
# "ユーザーが、顧客として、注文をしたい。"
#
class Context::Order
  include Context::ContextAccessor
  attr_accessor :order, :candidate_shops
  # Shop に追加されるフィ−ルド。その加盟店の、すでに確定している、特定の日付毎の配達指示の総数。
  FIELD_NAME_SCHEDULED_DELIVERY_COUNT = "scheduled_count"
  # Shop に追加されるフィ−ルド。注文明細の数量が、その加盟店が一回に扱える量の限界を超えていたら、
  # その加盟店が一回に扱える量の限界値が入る。そうでなければ、注文明細の数量が入る。
  FIELD_NAME_ACTUAL_QUANTITY = "actual_quantity"

  # 注文を受けることのできる、候補の加盟店群。注文明細毎にリストで保持。
  # そのリストが（self.candidate_shops）。
  CandidateShop = Struct.new(:order_detail, :shops)

  def initialize
    @candidate_shops = []
  end

  # Shopの、配達に関するリソースを表現。リストにして使用。
  class ShopDeliveryResource
    attr_accessor :shop
    def initialize(h)
      @shop = h[:shop] if h[:shop]
      @scheduled_count = {}
    end
    def new_scheduled_count(expected_date)
      # （仮に）スケジュ−ルされた配達指示の、日別の数を保持
      @scheduled_count[expected_date.to_s] =
        (@scheduled_count[expected_date.to_s] || 0) + 1
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