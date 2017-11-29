module Role::OrderNumberGenerator
  include IOrderManipulator

  def self.extended(order)
  end

  # 永続化前の仮の注文番号発番メソッド
  def build_psuedo_order_code
    prefix_psuedo_order_code = "--"
    return if !self.order_code.blank? or !self.new_record?
    latest_row = Order.order("id desc").max
    self.order_code ||=
      prefix_psuedo_order_code +
        ("%07d"%[(latest_row ? latest_row.id.to_i : 0) + 1])[-4..-1] +
        Time.now.to_i.to_s[-3..-1]
  end

  # 永続化直後の確定版注文番号発番メソッド
  def build_order_code
    prefix_order_code = "1C"
    raise("Order invalid.") if !self.id
    self.order_code = "#{prefix_order_code}%07d"%[self.id]
  end

  # 注文明細の連番発番メソッド
  def build_seq_code(order_detail)
    return if !order_detail.new_record?
    idx = self.order_details.
      find_index{|detail| order_detail.is_equive(detail) }
    self.order_details[idx].seq_code = "%02d"%[idx + 1]
  end
end