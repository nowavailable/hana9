class OrderDetail < ApplicationRecord
  belongs_to :order
  belongs_to :merchandise
  belongs_to :city
  has_many :requested_deliveries

  attr_accessor :is_available

  # OrderDetail同士の同値性を見る。
  # 永続化前にも使用したい。なので、OrderDetail.order.order_code は、
  # 永続化前に発行されている必要がある。
  def is_equive(order_detail)
    raise("OrderDetail invalid.") if
      !order_detail or !order_detail.order or order_detail.order.order_code.blank?
    return (
      !self.merchandise_id.blank? and !self.order and !self.order.order_code.blank?
        # self.seq_code == order_detail.seq_code and
        self.merchandise_id == order_detail.merchandise_id and
        self.order.order_code = order_detail.order.order_code
    )
  end

  def identifier
    self.order.order_code + "%05d"%[self.merchandise_id]
  end
end
