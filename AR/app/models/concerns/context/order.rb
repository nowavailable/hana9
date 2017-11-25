#
# "ユーザーが、顧客として、注文をしたい。"
#
class Context::Order
  attr_accessor :order, :candidate_shops
  # 注文を受けることのできる、候補の店舗群。注文明細毎にリストで保持。
  CandidateShop = Struct.new(:order_detail, :shops)

  # ある注文を、成立させられるかどうか判定する。
  def accept_check
    raise("Order invalid.") if !@order
    @candidate_shops = []

    execute_in_context do
      @order.extend Role::OrderAcceptor

      # 不成立の注文明細の有無を検査
      @order.build_acceptable_list

      # （店舗の稼働リミットのために）
      # 成立しない危険がある注文明細の有無を検査
      @candidate_shops.each do |candidate_shop|
        candidate_shop.shops.each do |shop|
          shop extend Role::ShopGuardian
        end
      end
      @order.build_risk_list
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
      seq_code: @order.generate_order_detail_code,
      merchandise_id: merchandise.id,
      city_id: city.id,
      quantity: quantity,
      expected_date: expected_date,
    )
  end

  def place_order

  end

  def display_form

  end

  def validate

  end
end