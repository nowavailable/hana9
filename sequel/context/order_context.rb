#
# "ユーザーが、顧客として、注文をしたい。"
#
class OrderContext
  attr_accessor :order, :acceptance

  # ある注文を、成立させられるかどうか判定する。
  def accept?
    raise ("Order invalid.") if !@order
    @order.extend OrderAcceptor
    @acceptance = (
      @order.order_details - @order.acceptable_list
    ).empty?
  end

  def append_order(merchandise, city, quantity, expected_date)
    @order ||= Order.new
    @order.add_order_detail(
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