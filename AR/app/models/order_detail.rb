class OrderDetail < ApplicationRecord
  belongs_to :order
  belongs_to :merchandise
  belongs_to :city
  has_many :requested_deliveries
end
