class RequestedDelivery < Sequel::Model
  many_to_one :shop
  many_to_one :order_detail

end