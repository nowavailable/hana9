class Order < ApplicationRecord
  has_many :order_details

  attr_accessor :on_risk

end
