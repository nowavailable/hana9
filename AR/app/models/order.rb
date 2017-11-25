class Order < ApplicationRecord
  has_many :order_details

  # 永続化前の仮の注文番号発番メソッド
  PREFIX_PSUEDO_ORDER_CODE = "--"
  def build_psuedo_order_code
    return if !self.order_code.blank? or !self.new_record?
    latest_row = Order.order("id desc").max
    self.order_code =
      PREFIX_PSUEDO_ORDER_CODE +
      ("%07d"%[(latest_row ? latest_row.id.to_i : 0) + 1])[-4..-1] +
      Time.now.to_i.to_s[-3..-1]
  end

  # 永続化直後の注文番号発番メソッド
  PREFIX_ORDER_CODE = "1C"
  def build_order_code
    raise("Order invalid.") if !self.id
    self.order_code = "#{PREFIX_ORDER_CODE}%07d"%[self.id]
  end

  # 注文明細用の番号発番準備メソッド
  def generate_order_detail_code
    return "%02d"%[self.order_details.length + 1]
  end

end
