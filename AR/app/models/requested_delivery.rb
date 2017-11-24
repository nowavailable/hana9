class RequestedDelivery < ApplicationRecord
  belongs_to :shop
  belongs_to :order_detail
end
